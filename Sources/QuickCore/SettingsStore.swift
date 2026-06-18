import Foundation

public final class SettingsStore {
    private enum Keys {
        static let systemPrompt = "systemPrompt"
        static let targetLanguage = "targetLanguage"
        static let baseURL = "baseURL"
        static let model = "model"
        static let doubleCopyInterval = "doubleCopyInterval"
        static let customShortcutEnabled = "customShortcutEnabled"
        static let customShortcutKey = "customShortcutKey"
        static let customShortcutCommand = "customShortcutCommand"
        static let customShortcutShift = "customShortcutShift"
        static let customShortcutOption = "customShortcutOption"
        static let customShortcutControl = "customShortcutControl"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppSettings {
        let defaultSettings = AppSettings.defaults
        let savedSystemPrompt = defaults.string(forKey: Keys.systemPrompt)
        let legacyTargetLanguage = defaults.string(forKey: Keys.targetLanguage)
        let systemPrompt = savedSystemPrompt
            ?? legacyTargetLanguage.map { "Translate the input into \($0). Return only the translated text." }
            ?? defaultSettings.systemPrompt
        let baseURL = defaults.string(forKey: Keys.baseURL) ?? defaultSettings.baseURL
        let model = defaults.string(forKey: Keys.model) ?? defaultSettings.model
        let interval = defaults.object(forKey: Keys.doubleCopyInterval) as? TimeInterval
            ?? defaultSettings.doubleCopyInterval
        let customShortcutEnabled = defaults.object(forKey: Keys.customShortcutEnabled) as? Bool
            ?? defaultSettings.customShortcutEnabled
        let customShortcutKey = defaults.string(forKey: Keys.customShortcutKey)
            ?? defaultSettings.customShortcutKey
        let customShortcutCommand = defaults.object(forKey: Keys.customShortcutCommand) as? Bool
            ?? defaultSettings.customShortcutCommand
        let customShortcutShift = defaults.object(forKey: Keys.customShortcutShift) as? Bool
            ?? defaultSettings.customShortcutShift
        let customShortcutOption = defaults.object(forKey: Keys.customShortcutOption) as? Bool
            ?? defaultSettings.customShortcutOption
        let customShortcutControl = defaults.object(forKey: Keys.customShortcutControl) as? Bool
            ?? defaultSettings.customShortcutControl
        return AppSettings(
            systemPrompt: systemPrompt,
            baseURL: baseURL,
            model: model,
            doubleCopyInterval: interval,
            customShortcutEnabled: customShortcutEnabled,
            customShortcutKey: customShortcutKey,
            customShortcutCommand: customShortcutCommand,
            customShortcutShift: customShortcutShift,
            customShortcutOption: customShortcutOption,
            customShortcutControl: customShortcutControl
        )
    }

    public func save(_ settings: AppSettings) {
        defaults.set(settings.systemPrompt, forKey: Keys.systemPrompt)
        defaults.set(settings.baseURL, forKey: Keys.baseURL)
        defaults.set(settings.model, forKey: Keys.model)
        defaults.set(settings.doubleCopyInterval, forKey: Keys.doubleCopyInterval)
        defaults.set(settings.customShortcutEnabled, forKey: Keys.customShortcutEnabled)
        defaults.set(settings.customShortcutKey, forKey: Keys.customShortcutKey)
        defaults.set(settings.customShortcutCommand, forKey: Keys.customShortcutCommand)
        defaults.set(settings.customShortcutShift, forKey: Keys.customShortcutShift)
        defaults.set(settings.customShortcutOption, forKey: Keys.customShortcutOption)
        defaults.set(settings.customShortcutControl, forKey: Keys.customShortcutControl)
    }
}
