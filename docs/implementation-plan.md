# Quick Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Quick, a native macOS Swift menu bar app that translates selected text after `cmd+c+c`.

**Architecture:** Use SwiftPM with a testable `QuickCore` library and a `Quick` executable target. `QuickCore` owns hotkey timing, settings, Keychain storage, and OpenAI request logic; the app target owns SwiftUI/AppKit presentation, menu bar lifecycle, permissions messaging, pasteboard access, and translation popup state.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Security.framework Keychain APIs, URLSession, Swift Testing/XCTest through SwiftPM.

---

## File Structure

- `Package.swift`: SwiftPM package definition.
- `Sources/QuickCore/DoubleCopyDetector.swift`: Detects two copy events within a configured interval.
- `Sources/QuickCore/TranslationModels.swift`: Shared translation state, app settings, and errors.
- `Sources/QuickCore/KeychainStore.swift`: Stores and retrieves the OpenAI API key in Keychain.
- `Sources/QuickCore/OpenAITranslator.swift`: Builds and sends OpenAI Responses API requests.
- `Sources/Quick/AppMain.swift`: SwiftUI app entry and menu bar commands.
- `Sources/Quick/AppDelegate.swift`: Startup permission prompt and global event monitor wiring.
- `Sources/Quick/SettingsView.swift`: Settings UI.
- `Sources/Quick/TranslationPanel.swift`: Floating translation popup.
- `Sources/Quick/PasteboardReader.swift`: Reads copied text without mutating pasteboard content.
- `Tests/QuickCoreTests/DoubleCopyDetectorTests.swift`: Double-copy timing tests.
- `Tests/QuickCoreTests/OpenAITranslatorTests.swift`: Request construction and response parsing tests.
- `AppBundle/Info.plist`: Metadata for packaging Quick as an app bundle.
- `Makefile`: Build a release binary and package `dist/Quick.app`.

## Tasks

- [ ] Create the SwiftPM package and documentation files.
- [ ] Add failing tests for double-copy detection.
- [ ] Implement double-copy detection.
- [ ] Add failing tests for OpenAI request and response behavior.
- [ ] Implement OpenAI translator.
- [ ] Implement settings and Keychain API-key storage.
- [ ] Implement macOS menu bar app, settings window, global event monitor, configurable shortcut support, pasteboard reader, and translation panel.
- [ ] Add app bundle metadata and packaging command.
- [ ] Run `swift test` and `swift build`.
