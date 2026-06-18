import XCTest
@testable import QuickCore

final class PaddleOCRCharacterDictionaryTests: XCTestCase {
    func testParsesCharacterDictionaryFromInferenceYAML() throws {
        let yaml = """
        PostProcess:
          name: CTCLabelDecode
          character_dict:
          - '!'
          - A
          - 你
          - '\\'
        """

        let dictionary = try PaddleOCRCharacterDictionary.parse(yaml)

        XCTAssertEqual(dictionary, ["!", "A", "你", "\\"])
    }

    func testThrowsWhenCharacterDictionaryIsMissing() {
        XCTAssertThrowsError(try PaddleOCRCharacterDictionary.parse("PostProcess: {}"))
    }
}
