import XCTest
@testable import QuickCore

final class OCRTextNormalizerTests: XCTestCase {
    func testRestoresSpacesAtLatinCaseAndDigitBoundaries() {
        XCTAssertEqual(
            OCRTextNormalizer.restoreLikelyLatinSpaces("HelloQuickOCR123"),
            "Hello Quick OCR 123"
        )
    }

    func testKeepsChineseTextCompact() {
        XCTAssertEqual(
            OCRTextNormalizer.restoreLikelyLatinSpaces("你好世界HelloQuick"),
            "你好世界Hello Quick"
        )
    }

    func testRemovesLayoutSpacesBetweenChineseCharacters() {
        XCTAssertEqual(
            OCRTextNormalizer.restoreLikelyLatinSpaces("你 好 世 界\n中 文识别 测试"),
            "你好世界\n中文识别测试"
        )
    }

    func testPreservesExistingWhitespaceAndNewlines() {
        XCTAssertEqual(
            OCRTextNormalizer.restoreLikelyLatinSpaces("FirstLine\nSecondLine42"),
            "First Line\nSecond Line 42"
        )
    }

    func testRestoresSpacesBetweenAcronymAndTitlecaseWord() {
        XCTAssertEqual(
            OCRTextNormalizer.restoreLikelyLatinSpaces("OCRResultText"),
            "OCR Result Text"
        )
    }
}
