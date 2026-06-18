import Foundation

public enum TranslationError: LocalizedError, Equatable {
    case missingAPIKey
    case emptyText
    case invalidBaseURL
    case invalidResponse
    case httpStatus(Int, String)
    case keychainStatus(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Open Quick settings and add one."
        case .emptyText:
            return "No text was copied."
        case .invalidBaseURL:
            return "OpenAI-compatible Base URL is invalid. Use a URL like https://api.openai.com or https://example.com/v1."
        case .invalidResponse:
            return "OpenAI returned a response Quick could not read."
        case let .httpStatus(status, message):
            return "OpenAI request failed with HTTP \(status): \(message)"
        case let .keychainStatus(status):
            return "Keychain operation failed with status \(status)."
        }
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var systemPrompt: String
    public var baseURL: String
    public var model: String
    public var doubleCopyInterval: TimeInterval
    public var customShortcutEnabled: Bool
    public var customShortcutKey: String
    public var customShortcutCommand: Bool
    public var customShortcutShift: Bool
    public var customShortcutOption: Bool
    public var customShortcutControl: Bool

    public init(
        systemPrompt: String = "You are a translation assistant. If I input English, translate it into Chinese; if I input Chinese, translate it into English.",
        baseURL: String = "https://api.openai.com",
        model: String = "gpt-5.4-mini",
        doubleCopyInterval: TimeInterval = 1.0,
        customShortcutEnabled: Bool = false,
        customShortcutKey: String = "t",
        customShortcutCommand: Bool = true,
        customShortcutShift: Bool = true,
        customShortcutOption: Bool = false,
        customShortcutControl: Bool = false
    ) {
        self.systemPrompt = systemPrompt
        self.baseURL = baseURL
        self.model = model
        self.doubleCopyInterval = doubleCopyInterval
        self.customShortcutEnabled = customShortcutEnabled
        self.customShortcutKey = customShortcutKey
        self.customShortcutCommand = customShortcutCommand
        self.customShortcutShift = customShortcutShift
        self.customShortcutOption = customShortcutOption
        self.customShortcutControl = customShortcutControl
    }

    public static let defaults = AppSettings()
}
