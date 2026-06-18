import XCTest
@testable import QuickCore

final class DoubleCopyDetectorTests: XCTestCase {
    func testCommandCTwiceInsideIntervalTriggers() {
        var detector = DoubleCopyDetector(interval: 0.7)

        let first = detector.registerCopyShortcut(at: 10.0)
        let second = detector.registerCopyShortcut(at: 10.5)

        XCTAssertFalse(first)
        XCTAssertTrue(second)
    }

    func testCommandCTwiceOutsideIntervalDoesNotTrigger() {
        var detector = DoubleCopyDetector(interval: 0.7)

        let first = detector.registerCopyShortcut(at: 10.0)
        let second = detector.registerCopyShortcut(at: 10.9)

        XCTAssertFalse(first)
        XCTAssertFalse(second)
    }

    func testTriggerResetsDetector() {
        var detector = DoubleCopyDetector(interval: 0.7)

        XCTAssertFalse(detector.registerCopyShortcut(at: 10.0))
        XCTAssertTrue(detector.registerCopyShortcut(at: 10.2))
        XCTAssertFalse(detector.registerCopyShortcut(at: 10.3))
    }
}
