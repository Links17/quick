import Foundation
import OnnxRuntimeBindings
import QuickOCR

struct ModelInspection {
    let path: String
    let inputs: [String]
    let outputs: [String]
}

func inspectModel(path: String) throws -> ModelInspection {
    let env = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)
    let options = try ORTSessionOptions()
    try options.setIntraOpNumThreads(1)
    let session = try ORTSession(env: env, modelPath: path, sessionOptions: options)
    let inputs = try session.inputNames()
    let outputs = try session.outputNames()
    return ModelInspection(path: path, inputs: inputs, outputs: outputs)
}

let arguments = Array(CommandLine.arguments.dropFirst())
let command = arguments.first ?? "inspect"
let root = arguments.dropFirst().first ?? "AppBundle/Resources/OCR"

do {
    switch command {
    case "inspect":
        let modelPaths = [
            "\(root)/ppocrv6_tiny_det.onnx",
            "\(root)/ppocrv6_tiny_rec.onnx",
        ]
        for modelPath in modelPaths {
            let inspection = try inspectModel(path: modelPath)
            print("model: \(inspection.path)")
            print("inputs: \(inspection.inputs.joined(separator: ","))")
            print("outputs: \(inspection.outputs.joined(separator: ","))")
        }
    case "recognize":
        guard arguments.count >= 3 else {
            fputs("Usage: QuickOCRInspect recognize <OCR resource dir> <image path>\n", stderr)
            exit(2)
        }
        let resourceDirectory = URL(fileURLWithPath: arguments[1])
        let imageURL = URL(fileURLWithPath: arguments[2])
        let data = try Data(contentsOf: imageURL)
        let service = try PaddleONNXOCRService(resourceDirectory: resourceDirectory)
        let text = try await service.recognizeText(in: data)
        print(text)
    default:
        fputs("Usage: QuickOCRInspect inspect [OCR resource dir]\n       QuickOCRInspect recognize <OCR resource dir> <image path>\n", stderr)
        exit(2)
    }
} catch {
    fputs("QuickOCRInspect failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
