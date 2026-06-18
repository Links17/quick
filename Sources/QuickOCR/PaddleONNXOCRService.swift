import AppKit
import Foundation
import OnnxRuntimeBindings
import QuickCore

public final class PaddleONNXOCRService: OCRService, @unchecked Sendable {
    private let env: ORTEnv
    private let detSession: ORTSession
    private let recSession: ORTSession
    private let postProcessor = DBPostProcessor()
    private let recDecoder: CTCLabelDecoder
    private let detInputName: String
    private let detOutputName: String
    private let recInputName: String
    private let recOutputName: String

    public init(resourceDirectory: URL? = nil) throws {
        let directory = try resourceDirectory ?? Self.defaultResourceDirectory()
        let detModelURL = directory.appendingPathComponent("ppocrv6_tiny_det.onnx")
        let recModelURL = directory.appendingPathComponent("ppocrv6_tiny_rec.onnx")
        let recYAMLURL = directory.appendingPathComponent("ppocrv6_tiny_rec.yml")

        let dictionary = try PaddleOCRCharacterDictionary.parse(String(contentsOf: recYAMLURL, encoding: .utf8))
        self.recDecoder = CTCLabelDecoder(characterDictionary: dictionary)

        self.env = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)
        let options = try ORTSessionOptions()
        try options.setIntraOpNumThreads(1)
        try options.setGraphOptimizationLevel(ORTGraphOptimizationLevel.all)

        self.detSession = try ORTSession(env: env, modelPath: detModelURL.path, sessionOptions: options)
        self.recSession = try ORTSession(env: env, modelPath: recModelURL.path, sessionOptions: options)

        self.detInputName = try detSession.inputNames().first ?? "x"
        self.detOutputName = try detSession.outputNames().first ?? "fetch_name_0"
        self.recInputName = try recSession.inputNames().first ?? "x"
        self.recOutputName = try recSession.outputNames().first ?? "fetch_name_0"
    }

    public func recognizeText(in imageData: Data) async throws -> String {
        guard let image = NSImage(data: imageData),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }

        let boxes = try detectTextBoxes(in: cgImage)
        let candidateImages: [CGImage]
        if boxes.isEmpty {
            candidateImages = [cgImage]
        } else {
            candidateImages = boxes.compactMap { box in
                cgImage.cropping(to: box.rect.clamped(toWidth: cgImage.width, height: cgImage.height))
            }
        }

        let items = try zip(candidateImages, boxes.isEmpty ? [OCRTextBox(rect: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height), score: 1)] : boxes).map { candidate, box in
            let tensor = try Self.makeRecognitionInputTensor(from: candidate)
            let output = try runRecognition(tensor: tensor)
            let text = recDecoder.decode(
                logits: output,
                spaceBlankRunThreshold: 3
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            return OCRTextItem(text: text, box: box)
        }

        let text = OCRTextNormalizer.restoreLikelyLatinSpaces(OCRTextLayout.format(items))
        guard !text.isEmpty else {
            throw OCRError.emptyResult
        }
        return text
    }

    private func detectTextBoxes(in cgImage: CGImage) throws -> [OCRTextBox] {
        let input = try Self.makeDetectionInputTensor(from: cgImage)
        let tensorData = NSMutableData(
            bytes: input.tensor,
            length: input.tensor.count * MemoryLayout<Float>.size
        )
        let value = try ORTValue(
            tensorData: tensorData,
            elementType: ORTTensorElementDataType.float,
            shape: [1, 3, NSNumber(value: input.height), NSNumber(value: input.width)]
        )
        let outputs = try detSession.run(
            withInputs: [detInputName: value],
            outputNames: Set([detOutputName]),
            runOptions: nil
        )
        guard let output = outputs[detOutputName] else {
            return []
        }

        let shape = try output.tensorTypeAndShapeInfo().shape.map(\.intValue)
        let outputData = try output.tensorData()
        let pointer = outputData.bytes.bindMemory(to: Float.self, capacity: outputData.length / MemoryLayout<Float>.size)
        let values = Array(UnsafeBufferPointer(start: pointer, count: outputData.length / MemoryLayout<Float>.size))

        let mapHeight: Int
        let mapWidth: Int
        if shape.count == 4 {
            mapHeight = shape[2]
            mapWidth = shape[3]
        } else if shape.count == 3 {
            mapHeight = shape[1]
            mapWidth = shape[2]
        } else {
            return []
        }

        return postProcessor.extractBoxes(
            probabilities: values,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            imageWidth: cgImage.width,
            imageHeight: cgImage.height
        )
    }

    private func runRecognition(tensor: [Float]) throws -> [[Float]] {
        let tensorData = NSMutableData(
            bytes: tensor,
            length: tensor.count * MemoryLayout<Float>.size
        )
        let input = try ORTValue(
            tensorData: tensorData,
            elementType: ORTTensorElementDataType.float,
            shape: [1, 3, 48, 320]
        )
        let outputs = try recSession.run(
            withInputs: [recInputName: input],
            outputNames: Set([recOutputName]),
            runOptions: nil
        )
        guard let output = outputs[recOutputName] else {
            throw OCRError.emptyResult
        }

        let shape = try output.tensorTypeAndShapeInfo().shape.map(\.intValue)
        let outputData = try output.tensorData()
        let pointer = outputData.bytes.bindMemory(to: Float.self, capacity: outputData.length / MemoryLayout<Float>.size)
        let values = Array(UnsafeBufferPointer(start: pointer, count: outputData.length / MemoryLayout<Float>.size))

        let timeSteps = shape.count >= 3 ? shape[1] : 0
        let classes = shape.count >= 3 ? shape[2] : 0
        guard timeSteps > 0, classes > 0, values.count >= timeSteps * classes else {
            throw OCRError.emptyResult
        }

        return (0..<timeSteps).map { row in
            let start = row * classes
            return Array(values[start..<(start + classes)])
        }
    }

    private static func makeRecognitionInputTensor(from cgImage: CGImage) throws -> [Float] {
        let sourceWidth = CGFloat(cgImage.width)
        let sourceHeight = CGFloat(cgImage.height)
        let targetHeight = 48
        let targetWidth = 320
        let resizedWidth = min(targetWidth, max(1, Int(ceil(CGFloat(targetHeight) * sourceWidth / sourceHeight))))
        let rgba = try draw(cgImage, width: resizedWidth, height: targetHeight)

        var tensor = Array(repeating: Float(0), count: 3 * targetHeight * targetWidth)
        for y in 0..<targetHeight {
            for x in 0..<resizedWidth {
                let pixelIndex = (y * resizedWidth + x) * 4
                let red = Float(rgba[pixelIndex]) / 255.0
                let green = Float(rgba[pixelIndex + 1]) / 255.0
                let blue = Float(rgba[pixelIndex + 2]) / 255.0
                let channels = [blue, green, red]

                for channel in 0..<3 {
                    let tensorIndex = channel * targetHeight * targetWidth + y * targetWidth + x
                    tensor[tensorIndex] = (channels[channel] - 0.5) / 0.5
                }
            }
        }

        return tensor
    }

    private static func makeDetectionInputTensor(from cgImage: CGImage) throws -> DetectionInput {
        let originalWidth = cgImage.width
        let originalHeight = cgImage.height
        let limitSideLength = 736
        let maxSideLimit = 4000

        var ratio: CGFloat = 1
        if min(originalWidth, originalHeight) < limitSideLength {
            ratio = CGFloat(limitSideLength) / CGFloat(min(originalWidth, originalHeight))
        }
        if CGFloat(max(originalWidth, originalHeight)) * ratio > CGFloat(maxSideLimit) {
            ratio = CGFloat(maxSideLimit) / (CGFloat(max(originalWidth, originalHeight)) * ratio) * ratio
        }

        let resizedWidth = max(32, Int(round(CGFloat(originalWidth) * ratio / 32) * 32))
        let resizedHeight = max(32, Int(round(CGFloat(originalHeight) * ratio / 32) * 32))
        let rgba = try draw(cgImage, width: resizedWidth, height: resizedHeight)

        var tensor = Array(repeating: Float(0), count: 3 * resizedHeight * resizedWidth)
        let mean: [Float] = [0.485, 0.456, 0.406]
        let std: [Float] = [0.229, 0.224, 0.225]

        for y in 0..<resizedHeight {
            for x in 0..<resizedWidth {
                let pixelIndex = (y * resizedWidth + x) * 4
                let red = Float(rgba[pixelIndex]) / 255.0
                let green = Float(rgba[pixelIndex + 1]) / 255.0
                let blue = Float(rgba[pixelIndex + 2]) / 255.0
                let channels = [blue, green, red]

                for channel in 0..<3 {
                    let tensorIndex = channel * resizedHeight * resizedWidth + y * resizedWidth + x
                    tensor[tensorIndex] = (channels[channel] - mean[channel]) / std[channel]
                }
            }
        }

        return DetectionInput(tensor: tensor, width: resizedWidth, height: resizedHeight)
    }

    private static func draw(_ cgImage: CGImage, width: Int, height: Int) throws -> [UInt8] {
        var pixels = Array(repeating: UInt8(255), count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw OCRError.invalidImage
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }

    private static func defaultResourceDirectory() throws -> URL {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("OCR"),
           FileManager.default.fileExists(atPath: url.path) {
            return url
        }

        let developmentURL = URL(fileURLWithPath: "AppBundle/Resources/OCR")
        if FileManager.default.fileExists(atPath: developmentURL.path) {
            return developmentURL
        }

        throw OCRError.missingModelResources
    }
}

private struct DetectionInput {
    let tensor: [Float]
    let width: Int
    let height: Int
}

private extension CGRect {
    func clamped(toWidth width: Int, height: Int) -> CGRect {
        let maxWidth = CGFloat(width)
        let maxHeight = CGFloat(height)
        let x = min(max(0, origin.x), maxWidth)
        let y = min(max(0, origin.y), maxHeight)
        let maxX = min(maxWidth, max(0, self.maxX))
        let maxY = min(maxHeight, max(0, self.maxY))
        return CGRect(x: x, y: y, width: max(1, maxX - x), height: max(1, maxY - y))
    }
}
