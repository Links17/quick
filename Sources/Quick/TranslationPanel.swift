import AppKit
import SwiftUI

@MainActor
final class TranslationPanelController {
    var onSubmitSource: ((String) -> Void)?

    private var panel: NSPanel?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    func showReady() {
        show(.ready)
    }

    func showLoading() {
        show(.loading(""))
    }

    func showLoading(source: String) {
        show(.loading(source))
    }

    func showOCRLoading() {
        show(.ocrLoading)
    }

    func showResult(_ text: String) {
        show(.message(text))
    }

    func showResult(source: String, translation: String) {
        show(.result(source, translation))
    }

    func showOCRResult(_ text: String) {
        show(.ocrResult(text))
    }

    func showError(_ message: String) {
        show(.error(nil, message))
    }

    func showError(source: String, message: String) {
        show(.error(source, message))
    }

    func showOCRError(_ message: String) {
        show(.ocrError(message))
    }

    private func show(_ state: TranslationPanelState) {
        let size = state.prefersSplitLayout ? NSSize(width: 620, height: 280) : NSSize(width: 360, height: 180)
        let origin = Self.panelOrigin(size: size)
        let frame = NSRect(origin: origin, size: size)

        let panel = self.panel ?? NSPanel(
            contentRect: frame,
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        NSApp.activate(ignoringOtherApps: true)
        panel.setFrame(frame, display: true)
        panel.title = "Quick"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.contentView = NSHostingView(
            rootView: TranslationPanelView(
                state: state,
                onSubmitSource: { [weak self] text in
                    self?.onSubmitSource?(text)
                }
            )
        )
        hideStandardWindowButtons(in: panel)
        panel.orderFrontRegardless()
        panel.makeKey()
        installDismissMonitors(for: panel)

        self.panel = panel
    }

    private func hideStandardWindowButtons(in panel: NSPanel) {
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
    }

    private func installDismissMonitors(for panel: NSPanel) {
        removeDismissMonitors()

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.closePanel()
            }
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self, weak panel] event in
            if let panel, event.window !== panel {
                Task { @MainActor in
                    self?.closePanel()
                }
            }
            return event
        }
    }

    private func closePanel() {
        panel?.orderOut(nil)
        removeDismissMonitors()
    }

    private func removeDismissMonitors() {
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }

        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
    }

    private static func panelOrigin(size: NSSize) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { screen in
            screen.frame.contains(mouse)
        } ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else {
            return NSPoint(x: 0, y: 0)
        }

        let x = visibleFrame.midX - size.width / 2
        let y = visibleFrame.midY - size.height / 2
        return NSPoint(x: x, y: y)
    }
}

private enum TranslationPanelState {
    case ready
    case loading(String)
    case result(String, String)
    case ocrLoading
    case ocrResult(String)
    case message(String)
    case error(String?, String)
    case ocrError(String)

    var prefersSplitLayout: Bool {
        switch self {
        case .loading, .result:
            return true
        case let .error(source, _):
            return source != nil
        case .ready, .ocrLoading, .ocrResult, .message, .ocrError:
            return false
        }
    }
}

private struct TranslationPanelView: View {
    let state: TranslationPanelState
    let onSubmitSource: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .imageScale(.medium)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            if let splitContent {
                SplitTranslationView(
                    source: splitContent.source,
                    target: splitContent.target,
                    targetIsError: splitContent.targetIsError,
                    targetIsLoading: splitContent.targetIsLoading,
                    onSubmitSource: onSubmitSource
                )
            } else {
                if isLoadingOnly {
                    VStack {
                        ProgressView()
                            .controlSize(.small)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        Text(bodyText)
                            .font(.system(size: 13))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }

    private var title: String {
        switch state {
        case .ready:
            return "Quick"
        case .loading:
            return "Translating"
        case .result:
            return "Translation"
        case .ocrLoading:
            return "OCR"
        case .ocrResult:
            return "OCR Result"
        case .message:
            return "Quick"
        case .error:
            return "Quick"
        case .ocrError:
            return "OCR"
        }
    }

    private var iconName: String {
        switch state {
        case .ready:
            return "character.bubble"
        case .loading:
            return "ellipsis.bubble"
        case .result:
            return "character.bubble"
        case .ocrLoading:
            return "viewfinder"
        case .ocrResult:
            return "text.viewfinder"
        case .message:
            return "character.bubble"
        case .error:
            return "exclamationmark.triangle"
        case .ocrError:
            return "exclamationmark.triangle"
        }
    }

    private var bodyText: String {
        switch state {
        case .ready:
            return "Select text or copy an image anywhere, then press cmd+c+c within about one second. Quick translates text and runs local OCR for images."
        case .loading:
            return "Waiting for OpenAI..."
        case let .result(_, text):
            return text
        case .ocrLoading:
            return ""
        case let .ocrResult(text):
            return text
        case let .message(text):
            return text
        case let .error(_, message):
            return message
        case let .ocrError(message):
            return message
        }
    }

    private var isLoadingOnly: Bool {
        switch state {
        case .ocrLoading:
            return true
        case .ready, .loading, .result, .ocrResult, .message, .error, .ocrError:
            return false
        }
    }

    private var splitContent: (source: String, target: String, targetIsError: Bool, targetIsLoading: Bool)? {
        switch state {
        case let .loading(source):
            return (source, "", false, true)
        case let .result(source, translation):
            return (source, translation, false, false)
        case let .error(source?, message):
            return (source, message, true, false)
        case .ready, .ocrLoading, .ocrResult, .message, .error(nil, _), .ocrError:
            return nil
        }
    }
}

private struct SplitTranslationView: View {
    @State private var sourceText: String

    let target: String
    let targetIsError: Bool
    let targetIsLoading: Bool
    let onSubmitSource: (String) -> Void

    init(
        source: String,
        target: String,
        targetIsError: Bool,
        targetIsLoading: Bool,
        onSubmitSource: @escaping (String) -> Void
    ) {
        self._sourceText = State(initialValue: source)
        self.target = target
        self.targetIsError = targetIsError
        self.targetIsLoading = targetIsLoading
        self.onSubmitSource = onSubmitSource
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Original")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Type source text", text: $sourceText, axis: .vertical)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                    .lineLimit(6...10)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onSubmit {
                        submit()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 6) {
                Text(" ")
                    .font(.caption)

                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Translation")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if targetIsLoading {
                    VStack {
                        ProgressView()
                            .controlSize(.small)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.top, 8)
                } else {
                    ScrollView {
                        Text(target)
                            .font(.system(size: 13))
                            .foregroundStyle(targetIsError ? .red : .primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func submit() {
        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        onSubmitSource(sourceText)
    }
}
