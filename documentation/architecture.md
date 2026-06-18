# Architecture

Quick is a native macOS menu bar utility for shortcut translation and local OCR.

## Stack

- Swift Package Manager.
- SwiftUI for settings and popup content.
- AppKit for menu bar integration, floating panels, pasteboard access, and event monitors.
- Security.framework for Keychain storage.
- URLSession for OpenAI-compatible API calls.
- ONNX Runtime for local PP-OCRv6 tiny OCR.

## Components

- `Sources/QuickCore`
  - `CopyGestureDetector`: requires pasteboard changes to happen while `cmd` is held before treating them as `cmd+c+c`.
  - `DoubleCopyDetector`: generic timing detector used by copy gesture logic.
  - `OpenAITranslator`: builds Responses API requests and parses translated output.
  - `SettingsStore`: persists non-secret settings in `UserDefaults`.
  - `KeychainStore`: persists the OpenAI API key in macOS Keychain.
  - `TranslationModels`: shared settings and error types.
  - `ClipboardContent`: routes pasteboard text vs image content.
  - `DBPostProcessor`, `CTCLabelDecoder`, `OCRTextLayout`, `OCRTextNormalizer`: OCR support logic.
- `Sources/QuickOCR`
  - `PaddleONNXOCRService`: loads bundled PP-OCRv6 tiny detection/recognition ONNX models and recognizes copied images locally.
- `Sources/Quick`
  - `AppDelegate`: starts menu bar app, settings window, pasteboard monitor, and optional global shortcut monitor.
  - `SettingsView`: configuration UI.
  - `TranslationPanel`: floating translation popup.
- `PasteboardReader`: small wrapper around `NSPasteboard` for supported text/image content.

## Trust Boundaries

- Local user input enters through the system pasteboard and editable source text field.
- Secrets enter through Settings and are stored in Keychain.
- Translation text leaves the machine through the configured OpenAI-compatible Base URL.
- Copied image OCR stays on-device through bundled ONNX models.
- The Base URL is user-controlled, so users choose which provider receives source text.

## Related Documents

- `flows.md`
- `permissions.md`
- `variables.md`
