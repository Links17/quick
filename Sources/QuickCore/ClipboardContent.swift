import Foundation

public enum ClipboardContent: Equatable {
    case text(String)
    case imageData(Data)

    public var hasSupportedContent: Bool {
        switch self {
        case let .text(value):
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case let .imageData(data):
            return !data.isEmpty
        }
    }
}

public enum ClipboardAction: Equatable {
    case translate(String)
    case recognizeImage(Data)
    case ignore
}

public enum ClipboardActionRouter {
    public static func route(_ content: ClipboardContent) -> ClipboardAction {
        guard content.hasSupportedContent else {
            return .ignore
        }

        switch content {
        case let .text(value):
            return .translate(value)
        case let .imageData(data):
            return .recognizeImage(data)
        }
    }
}
