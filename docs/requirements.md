# Quick Requirements

## Product

Quick is a native macOS menu bar app for fast translation of currently selected text.

## User Need

The user wants a lightweight alternative to Deel's shortcut translation workflow while keeping the fast "copy twice to translate" interaction.

## Functional Requirements

- Product name: Quick.
- Platform: macOS.
- Implementation language: Swift.
- App style: menu bar utility, no landing page or main document window.
- Default shortcut behavior: pressing `cmd+c+c` within a short time window copies the selected text and opens a translation popup.
- Pasteboard changes only count toward `cmd+c+c` while the `cmd` key is down, so ordinary mouse or trackpad interactions that modify the pasteboard do not trigger translation.
- Optional custom shortcut behavior: a configured single keyboard shortcut can copy the current selection and then translate it.
- The first `cmd+c` must keep normal system copy behavior.
- The app reads text from the system pasteboard after the second copy.
- The app translates copied text using a user-configured system prompt.
- Translation provider: OpenAI API.
- API endpoint base URL is configurable for OpenAI-compatible third-party providers.
- Default Base URL is `https://api.openai.com`; compatible providers can use a provider root URL such as `https://example.com`, or a versioned URL such as `https://example.com/v1`.
- API key is configured in the app settings.
- API key must be stored in macOS Keychain, not in a plain text settings file.
- Settings must include:
  - OpenAI API key.
  - OpenAI-compatible Base URL.
  - System prompt.
  - OpenAI model name.
  - Double-copy detection interval.
  - Optional custom single shortcut.
- Translation result is shown in a lightweight floating popup.
- Translation popup uses a two-column layout for translations: editable source text on the left, translated text on the right, separated by `｜`.
- Pressing Return while editing the source text retranslates the current source text.
- Clicking outside the translation popup closes it.
- If the API key is missing, Quick opens settings and tells the user to configure it.
- If the pasteboard has no text, Quick shows a lightweight message.
- If macOS permissions are missing, Quick shows guidance for Input Monitoring and Accessibility permissions.

## Non-Goals For The First Version

- Windows or Linux support.
- Offline translation.
- Replacing selected text in-place.
- Full shortcut recorder UI with arbitrary non-keyboard inputs.
- Translation history.
- OCR or image translation.

## macOS Permissions

Quick needs permission to observe global key events while another app is focused. The user may need to grant Quick access in:

- System Settings -> Privacy & Security -> Input Monitoring.
- System Settings -> Privacy & Security -> Accessibility.

## Success Criteria

- `swift test` passes.
- `swift build` builds the app.
- Running Quick shows a menu bar item.
- Setting an OpenAI API key and system prompt allows `cmd+c+c` to translate copied text.
- Missing API key, empty pasteboard, and API failures are reported without modifying the pasteboard content.
