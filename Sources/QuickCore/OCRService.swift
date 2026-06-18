import Foundation

public protocol OCRService: Sendable {
    func recognizeText(in imageData: Data) async throws -> String
}

public enum OCRError: LocalizedError, Equatable {
    case engineUnavailable
    case emptyResult
    case missingCharacterDictionary
    case missingModelResources
    case invalidImage

    public var errorDescription: String? {
        switch self {
        case .engineUnavailable:
            return "Local OCR engine is not available yet."
        case .emptyResult:
            return "No text was found in the image."
        case .missingCharacterDictionary:
            return "OCR character dictionary is missing."
        case .missingModelResources:
            return "OCR model resources are missing."
        case .invalidImage:
            return "Copied image could not be read."
        }
    }
}
