import XCTest
@testable import QuickCore

final class ClipboardContentTests: XCTestCase {
    func testTextContentIsSupportedWhenTrimmedTextIsNotEmpty() {
        XCTAssertTrue(ClipboardContent.text(" hello ").hasSupportedContent)
    }

    func testTextContentIsUnsupportedWhenTextIsEmpty() {
        XCTAssertFalse(ClipboardContent.text(" \n\t ").hasSupportedContent)
    }

    func testImageContentIsSupportedWhenDataIsNotEmpty() {
        XCTAssertTrue(ClipboardContent.imageData(Data([0x89, 0x50, 0x4E, 0x47])).hasSupportedContent)
    }

    func testImageContentIsUnsupportedWhenDataIsEmpty() {
        XCTAssertFalse(ClipboardContent.imageData(Data()).hasSupportedContent)
    }
}
