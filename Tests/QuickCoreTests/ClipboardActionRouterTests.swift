import XCTest
@testable import QuickCore

final class ClipboardActionRouterTests: XCTestCase {
    func testRoutesTextClipboardContentToTranslation() {
        let action = ClipboardActionRouter.route(.text("Hello"))

        XCTAssertEqual(action, .translate("Hello"))
    }

    func testRoutesImageClipboardContentToOCR() {
        let data = Data([1, 2, 3])
        let action = ClipboardActionRouter.route(.imageData(data))

        XCTAssertEqual(action, .recognizeImage(data))
    }

    func testRoutesEmptyClipboardContentToIgnore() {
        XCTAssertEqual(ClipboardActionRouter.route(.text("   ")), .ignore)
        XCTAssertEqual(ClipboardActionRouter.route(.imageData(Data())), .ignore)
    }
}
