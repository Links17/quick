import XCTest
@testable import QuickCore

final class CopyGestureDetectorTests: XCTestCase {
    func testTwoCommandPasteboardChangesInsideIntervalTrigger() {
        var detector = CopyGestureDetector(interval: 1.0)

        let first = detector.registerPasteboardChange(at: 10.0, isCommandKeyDown: true, hasSupportedContent: true)
        let second = detector.registerPasteboardChange(at: 10.6, isCommandKeyDown: true, hasSupportedContent: true)

        XCTAssertFalse(first)
        XCTAssertTrue(second)
    }

    func testPasteboardChangesWithoutCommandDoNotTrigger() {
        var detector = CopyGestureDetector(interval: 1.0)

        XCTAssertFalse(detector.registerPasteboardChange(at: 10.0, isCommandKeyDown: false, hasSupportedContent: true))
        XCTAssertFalse(detector.registerPasteboardChange(at: 10.4, isCommandKeyDown: false, hasSupportedContent: true))
    }

    func testNonCommandPasteboardChangeResetsPendingCommandCopy() {
        var detector = CopyGestureDetector(interval: 1.0)

        XCTAssertFalse(detector.registerPasteboardChange(at: 10.0, isCommandKeyDown: true, hasSupportedContent: true))
        XCTAssertFalse(detector.registerPasteboardChange(at: 10.2, isCommandKeyDown: false, hasSupportedContent: true))
        XCTAssertFalse(detector.registerPasteboardChange(at: 10.4, isCommandKeyDown: true, hasSupportedContent: true))
    }

    func testEmptyPasteboardChangeDoesNotTrigger() {
        var detector = CopyGestureDetector(interval: 1.0)

        XCTAssertFalse(detector.registerPasteboardChange(at: 10.0, isCommandKeyDown: true, hasSupportedContent: false))
        XCTAssertFalse(detector.registerPasteboardChange(at: 10.3, isCommandKeyDown: true, hasSupportedContent: true))
    }
}
