import Foundation

public struct CopyGestureDetector: Sendable {
    private var detector: DoubleCopyDetector

    public init(interval: TimeInterval) {
        self.detector = DoubleCopyDetector(interval: interval)
    }

    public mutating func registerPasteboardChange(
        at time: TimeInterval,
        isCommandKeyDown: Bool,
        hasText: Bool
    ) -> Bool {
        guard isCommandKeyDown, hasText else {
            detector.reset()
            return false
        }

        return detector.registerCopyShortcut(at: time)
    }
}
