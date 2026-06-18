# Flows

## Default `cmd+c+c` Processing

1. User selects text or copies an image in another app.
2. User holds `cmd` and presses `c` twice.
3. macOS updates the pasteboard for each copy.
4. Quick polls pasteboard `changeCount`.
5. Quick only counts a pasteboard change if the `cmd` key is down and supported pasteboard content is present.
6. Two qualifying changes inside the configured interval trigger processing.
7. Quick reads pasteboard content and routes it by type.
8. Text content is sent as Responses API `input` with the configured System Prompt as `instructions`.
9. Image content is processed locally with bundled PP-OCRv6 tiny ONNX models.
10. Quick shows a floating translation or OCR popup.

Side effects:

- Reads supported pasteboard content.
- Sends source text to the configured provider for text translation.
- Keeps copied image OCR local.
- Shows a local popup.

## Manual Translation From Popup

1. User edits the source pane.
2. User presses Return.
3. Quick sends edited text as Responses API `input`.
4. Quick replaces the translation result.

Side effects:

- Sends edited source text to the configured provider.
- Does not write to the pasteboard.

## Settings Update

1. User opens `Quick -> Settings...`.
2. User edits API key, Base URL, model, System Prompt, interval, or custom shortcut settings.
3. User clicks Save.
4. Quick stores the API key in Keychain.
5. Quick stores non-secret settings in `UserDefaults`.

Side effects:

- Writes secret to Keychain.
- Writes non-secret configuration to local defaults.
