# Quick

Quick is a lightweight macOS menu bar translator built around one gesture: select text anywhere, press `cmd+c+c`, and get an editable translation popup.

It is designed for people who like instant shortcut translation but want a small native tool with configurable OpenAI-compatible providers.

## Highlights

- Native Swift macOS menu bar app.
- Default shortcut: `cmd+c+c`.
- No keyboard monitoring permission needed for the default shortcut.
- Editable source text on the left, translated text on the right.
- Press Return in the source pane to translate again.
- Click outside the popup to dismiss it.
- Configurable OpenAI-compatible Base URL.
- Configurable System Prompt sent as the Responses API `instructions` field.
- API key stored in macOS Keychain.

## How It Works

Quick watches pasteboard changes instead of global keyboard events for the default shortcut.

1. Select text in any app.
2. Hold `cmd` and press `c` twice quickly.
3. Quick sees two text pasteboard changes while `cmd` is down.
4. Quick sends the selected text to the configured OpenAI-compatible endpoint.
5. The popup shows original text and translation side by side.

This avoids the fragile macOS Input Monitoring path for the default gesture. Input Monitoring and Accessibility are only needed if you enable a custom shortcut that simulates copy.

## Settings

Open the menu bar item `Quick -> Settings...`.

| Setting | Purpose |
| --- | --- |
| API Key | OpenAI or OpenAI-compatible provider key. Stored in Keychain. |
| Base URL | Provider root or endpoint, such as `https://api.openai.com`, `https://example.com/v1`, or `https://example.com/v1/responses`. |
| Model | Any model name supported by your provider. |
| System Prompt | Sent as the Responses API `instructions` field. |
| Double-copy interval | Time window for detecting `cmd+c+c`. |
| Custom shortcut | Optional single shortcut that copies and translates. |

Default System Prompt:

```text
You are a translation assistant. If I input English, translate it into Chinese; if I input Chinese, translate it into English.
```

## Build

Requirements:

- macOS 13 or newer
- Xcode with Swift 6 support

Build and test:

```bash
swift build
swift test
```

Package a local `.app` bundle:

```bash
make app
open dist/Quick.app
```

## Development Notes

- `QuickCore` contains testable logic: copy gesture detection, settings, Keychain access, OpenAI request building, and response parsing.
- `Quick` contains AppKit/SwiftUI integration: menu bar item, settings window, pasteboard monitor, popup UI.
- The local packaged app is unsigned. macOS Keychain and privacy permissions may ask again after rebuilds because the binary identity changes.

## Project Structure

```text
Sources/QuickCore/      Core logic and tests
Sources/Quick/          macOS app UI and system integration
Tests/QuickCoreTests/   Unit tests
AppBundle/              Minimal app bundle metadata
docs/                   Product requirements and implementation notes
documentation/          Reviewer-oriented system documentation
```

## Verification

Current verification command:

```bash
swift test
```

