import Foundation
import QuickCore

struct PlaceholderOCRService: OCRService {
    func recognizeText(in imageData: Data) async throws -> String {
        throw OCRError.engineUnavailable
    }
}
