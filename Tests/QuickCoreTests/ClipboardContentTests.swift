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

    func testResolvePrefersImageDataOverTextWhenBothExist() {
        let content = ClipboardContent.resolve(
            text: "/tmp/copied-image.png",
            imageData: Data([1, 2, 3])
        )

        XCTAssertEqual(content, .imageData(Data([1, 2, 3])))
    }

    func testResolveFallsBackToNonEmptyText() {
        let content = ClipboardContent.resolve(text: "Hello", imageData: nil)

        XCTAssertEqual(content, .text("Hello"))
    }

    func testResolveReturnsEmptyTextWhenNoSupportedContentExists() {
        let content = ClipboardContent.resolve(text: "  ", imageData: Data())

        XCTAssertEqual(content, .text(""))
    }
}
