import AppKit
import ApplicationServices
import QuickCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        QuickAppModel.shared.start()
    }
}

@MainActor
final class QuickAppModel: NSObject, ObservableObject {
    static let shared = QuickAppModel()

    @Published var settings: AppSettings
    @Published var apiKey: String
    @Published var statusMessage: String = ""

    private let settingsStore: SettingsStore
    private let keychainStore: KeychainStore
    private let translator: OpenAITranslator
    private let ocrService: OCRService
    private let pasteboardReader: PasteboardReader
    private let panelController: TranslationPanelController
    private var copyGestureDetector: CopyGestureDetector
    private var eventMonitor: Any?
    private var pasteboardTimer: Timer?
    private var lastPasteboardChangeCount: Int = 0
    private var isTranslating = false
    private var statusItem: NSStatusItem?
    private var settingsWindowController: NSWindowController?

    private init(
        settingsStore: SettingsStore = SettingsStore(),
        keychainStore: KeychainStore = KeychainStore(),
        translator: OpenAITranslator = OpenAITranslator(),
        ocrService: OCRService = QuickAppModel.makeDefaultOCRService(),
        pasteboardReader: PasteboardReader = PasteboardReader(),
        panelController: TranslationPanelController = TranslationPanelController()
    ) {
        self.settingsStore = settingsStore
        self.keychainStore = keychainStore
        self.translator = translator
        self.ocrService = ocrService
        self.pasteboardReader = pasteboardReader
        self.panelController = panelController

        let loadedSettings = settingsStore.load()
        self.settings = loadedSettings
        self.copyGestureDetector = CopyGestureDetector(interval: loadedSettings.doubleCopyInterval)
        self.apiKey = (try? keychainStore.readAPIKey()) ?? ""
        super.init()

        self.panelController.onSubmitSource = { [weak self] text in
            Task { @MainActor in
                await self?.translateText(text)
            }
        }
    }

    private static func makeDefaultOCRService() -> OCRService {
        (try? PaddleONNXOCRService()) ?? PlaceholderOCRService()
    }

    func start() {
        installStatusItem()
        installPasteboardMonitor()
        installGlobalCopyMonitor()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.panelController.showReady()
        }
    }

    func saveSettings() {
        settingsStore.save(settings)
        copyGestureDetector = CopyGestureDetector(interval: settings.doubleCopyInterval)

        do {
            try keychainStore.saveAPIKey(apiKey)
            statusMessage = "Settings saved."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        if let settingsWindowController {
            settingsWindowController.showWindow(nil)
            settingsWindowController.window?.makeKeyAndOrderFront(nil)
            return
        }

        let hostingController = NSHostingController(
            rootView: SettingsView()
                .environmentObject(self)
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Quick Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 560, height: 620))
        window.minSize = NSSize(width: 520, height: 520)
        window.center()

        let controller = NSWindowController(window: window)
        self.settingsWindowController = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }

    func translateCopiedText() async {
        do {
            try await Task.sleep(nanoseconds: 120_000_000)
        } catch {
            return
        }

        let content = pasteboardReader.readContent()
        await handleClipboardContent(content)
    }

    func handleClipboardContent(_ content: ClipboardContent) async {
        switch ClipboardActionRouter.route(content) {
        case let .translate(text):
            await translateText(text)
        case let .recognizeImage(data):
            await recognizeImage(data)
        case .ignore:
            panelController.showError(TranslationError.emptyText.localizedDescription)
        }
    }

    func translateText(_ sourceText: String) async {
        if isTranslating {
            return
        }
        isTranslating = true
        defer {
            isTranslating = false
        }

        panelController.showLoading(source: sourceText)

        do {
            let trimmedSourceText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSourceText.isEmpty else {
                throw TranslationError.emptyText
            }

            let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else {
                throw TranslationError.missingAPIKey
            }

            let translated = try await translator.translate(
                text: trimmedSourceText,
                systemPrompt: settings.systemPrompt,
                apiKey: key,
                baseURL: settings.baseURL,
                model: settings.model
            )
            panelController.showResult(source: sourceText, translation: translated)
        } catch {
            panelController.showError(source: sourceText, message: error.localizedDescription)
        }
    }

    func recognizeImage(_ imageData: Data) async {
        if isTranslating {
            return
        }
        isTranslating = true
        defer {
            isTranslating = false
        }

        panelController.showLoading(source: "Image OCR")

        do {
            let recognizedText = try await ocrService.recognizeText(in: imageData)
            let trimmedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else {
                throw OCRError.emptyResult
            }
            panelController.showResult(source: "Image OCR", translation: trimmedText)
        } catch {
            panelController.showError(source: "Image OCR", message: error.localizedDescription)
        }
    }

    private func installGlobalCopyMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handleGlobalKeyDown(event)
            }
        }
    }

    private func installPasteboardMonitor() {
        pasteboardTimer?.invalidate()
        lastPasteboardChangeCount = pasteboardReader.changeCount()

        pasteboardTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPasteboard()
            }
        }
    }

    private func pollPasteboard() {
        let currentChangeCount = pasteboardReader.changeCount()
        guard currentChangeCount != lastPasteboardChangeCount else {
            return
        }

        lastPasteboardChangeCount = currentChangeCount

        let content = pasteboardReader.readContent()
        let hasSupportedContent = content.hasSupportedContent
        let isCommandKeyDown = CGEventSource.flagsState(.combinedSessionState).contains(.maskCommand)

        if copyGestureDetector.registerPasteboardChange(
            at: Date().timeIntervalSinceReferenceDate,
            isCommandKeyDown: isCommandKeyDown,
            hasSupportedContent: hasSupportedContent
        ) {
            Task {
                await translateCopiedText()
            }
        }
    }

    private func installStatusItem() {
        if statusItem != nil {
            return
        }

        let item = NSStatusBar.system.statusItem(withLength: 24)
        item.button?.image = makeStatusBarIcon()
        item.button?.imagePosition = .imageOnly
        item.button?.title = ""
        item.button?.toolTip = "Quick"

        let menu = NSMenu()
        let translateItem = NSMenuItem(
            title: "Translate Clipboard",
            action: #selector(translateClipboardFromMenu),
            keyEquivalent: "t"
        )
        translateItem.keyEquivalentModifierMask = [.command]
        translateItem.target = self
        menu.addItem(translateItem)

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        menu.addItem(settingsItem)

        let permissionsItem = NSMenuItem(
            title: "Check Permissions",
            action: #selector(checkPermissionsFromMenu),
            keyEquivalent: ""
        )
        permissionsItem.target = self
        menu.addItem(permissionsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Quick",
            action: #selector(quitFromMenu),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    private func makeStatusBarIcon() -> NSImage {
        let image = NSImage(systemSymbolName: "character.bubble", accessibilityDescription: "Quick")
            ?? NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "Quick")
            ?? NSImage(size: NSSize(width: 18, height: 18))
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        image.accessibilityDescription = "Quick"
        return image
    }

    @objc private func translateClipboardFromMenu() {
        Task {
            await translateCopiedText()
        }
    }

    @objc private func openSettingsFromMenu() {
        openSettings()
    }

    @objc private func checkPermissionsFromMenu() {
        let permissions = currentKeyboardPermissions()
        let customShortcutLine = permissions.inputMonitoring
            ? "Custom shortcut key detection: ready."
            : "Custom shortcut key detection: Input Monitoring is not granted."
        let simulatedCopyLine = permissions.accessibility
            ? "Custom shortcut copy simulation: ready."
            : "Custom shortcut copy simulation: Accessibility is not granted."

        panelController.showResult(
            """
            cmd+c+c: ready. It uses pasteboard changes and does not need keyboard monitoring.
            \(customShortcutLine)
            \(simulatedCopyLine)
            """
        )
    }

    @objc private func quitFromMenu() {
        NSApp.terminate(nil)
    }

    private func handleGlobalKeyDown(_ event: NSEvent) {
        if isConfiguredShortcut(event) {
            Task {
                await copySelectionThenTranslate()
            }
            return
        }

        return
    }

    private func copySelectionThenTranslate() async {
        postCommandC()
        await translateCopiedText()
    }

    private func isCommandC(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return event.keyCode == 8 && flags.contains(.command) && !event.isARepeat
    }

    private func isConfiguredShortcut(_ event: NSEvent) -> Bool {
        guard settings.customShortcutEnabled, !event.isARepeat else {
            return false
        }

        let expectedKey = settings.customShortcutKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard expectedKey.count == 1,
              event.charactersIgnoringModifiers?.lowercased() == expectedKey else {
            return false
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags.contains(.command) == settings.customShortcutCommand
            && flags.contains(.shift) == settings.customShortcutShift
            && flags.contains(.option) == settings.customShortcutOption
            && flags.contains(.control) == settings.customShortcutControl
    }

    private func postCommandC() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyCodeForC: CGKeyCode = 8
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForC, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForC, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private struct KeyboardPermissions {
        let accessibility: Bool
        let inputMonitoring: Bool
    }

    private func currentKeyboardPermissions() -> KeyboardPermissions {
        let accessibilityReady = AXIsProcessTrusted()
        let inputMonitoringReady: Bool
        if #available(macOS 10.15, *) {
            inputMonitoringReady = CGPreflightListenEventAccess()
        } else {
            inputMonitoringReady = true
        }
        return KeyboardPermissions(accessibility: accessibilityReady, inputMonitoring: inputMonitoringReady)
    }

    private func requestKeyboardPermissions() -> KeyboardPermissions {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let accessibilityReady = AXIsProcessTrustedWithOptions(options)
        let inputMonitoringReady: Bool
        if #available(macOS 10.15, *) {
            inputMonitoringReady = CGRequestListenEventAccess()
        } else {
            inputMonitoringReady = true
        }

        if !inputMonitoringReady {
            statusMessage = "cmd+c+c is ready. Input Monitoring is only needed for custom shortcuts."
        } else if !accessibilityReady {
            statusMessage = "cmd+c+c is ready. Accessibility is only needed for custom shortcut copy simulation."
        }
        return KeyboardPermissions(accessibility: accessibilityReady, inputMonitoring: inputMonitoringReady)
    }

    private func showPermissionsMessage(_ permissions: KeyboardPermissions) {
        let inputLine = permissions.inputMonitoring ? "Input Monitoring: granted" : "Input Monitoring: not granted"
        let accessibilityLine = permissions.accessibility ? "Accessibility: granted" : "Accessibility: not granted"
        panelController.showError(
            """
            cmd+c+c does not need these permissions anymore.
            \(inputLine)
            \(accessibilityLine)

            Permissions only affect custom shortcuts. The default cmd+c+c shortcut works by watching pasteboard changes.
            """
        )
    }
}
