import CoreGraphics
import XCTest
@testable import QuickCore

final class OCRTextLayoutTests: XCTestCase {
    func testJoinsBoxesOnSameLineWithSpacesWhenThereIsHorizontalGap() {
        let items = [
            OCRTextItem(text: "Hello", box: OCRTextBox(rect: CGRect(x: 10, y: 20, width: 50, height: 20), score: 0.9)),
            OCRTextItem(text: "Quick", box: OCRTextBox(rect: CGRect(x: 80, y: 22, width: 55, height: 18), score: 0.9)),
            OCRTextItem(text: "OCR", box: OCRTextBox(rect: CGRect(x: 160, y: 19, width: 42, height: 21), score: 0.9)),
        ]

        XCTAssertEqual(OCRTextLayout.format(items), "Hello Quick OCR")
    }

    func testSeparatesDifferentRowsWithNewlines() {
        let items = [
            OCRTextItem(text: "First", box: OCRTextBox(rect: CGRect(x: 90, y: 80, width: 40, height: 18), score: 0.9)),
            OCRTextItem(text: "Line", box: OCRTextBox(rect: CGRect(x: 10, y: 80, width: 45, height: 18), score: 0.9)),
            OCRTextItem(text: "Second", box: OCRTextBox(rect: CGRect(x: 10, y: 130, width: 70, height: 18), score: 0.9)),
        ]

        XCTAssertEqual(OCRTextLayout.format(items), "Line First\nSecond")
    }

    func testFiltersEmptyText() {
        let items = [
            OCRTextItem(text: " ", box: OCRTextBox(rect: CGRect(x: 0, y: 0, width: 10, height: 10), score: 0.9)),
            OCRTextItem(text: "Text", box: OCRTextBox(rect: CGRect(x: 20, y: 0, width: 20, height: 10), score: 0.9)),
        ]

        XCTAssertEqual(OCRTextLayout.format(items), "Text")
    }
}
