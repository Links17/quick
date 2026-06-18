import Foundation

public struct DoubleCopyDetector: Sendable {
    public let interval: TimeInterval
    private var previousCopyTime: TimeInterval?

    public init(interval: TimeInterval) {
        self.interval = interval
    }

    public mutating func registerCopyShortcut(at time: TimeInterval) -> Bool {
        guard let lastCopyTime = previousCopyTime else {
            previousCopyTime = time
            return false
        }

        let isDoubleCopy = time - lastCopyTime <= interval
        if isDoubleCopy {
            previousCopyTime = nil
        } else {
            previousCopyTime = time
        }
        return isDoubleCopy
    }

    public mutating func reset() {
        previousCopyTime = nil
    }
}
