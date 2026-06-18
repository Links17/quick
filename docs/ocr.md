# OCR

Quick v0.2.0 adds local OCR for copied images while keeping the same `cmd+c+c` workflow.

## User Flow

1. Copy an image or screenshot in any macOS app.
2. Hold `cmd` and press `c` twice quickly.
3. Quick reads image data from the system pasteboard.
4. Quick runs OCR locally.
5. Quick shows the recognized text in the floating popup.

Text and image inputs are routed differently:

| Clipboard content | Behavior |
| --- | --- |
| Text | Sent to the configured OpenAI-compatible provider for translation. |
| Image data | Processed locally with OCR. |
| Image data plus text or file path | Image data takes priority. |
| Empty or unsupported content | Quick shows a lightweight error message. |

## Privacy

Image OCR runs on device. Copied images are not sent to OpenAI or third-party API providers.

Only text translation uses the configured API key, Base URL, model, and System Prompt.

## Implementation

OCR is implemented in Swift with ONNX Runtime and bundled PP-OCRv6 tiny models.

Bundled assets:

| Asset | Purpose |
| --- | --- |
| `AppBundle/Resources/OCR/ppocrv6_tiny_det.onnx` | Text detection model. |
| `AppBundle/Resources/OCR/ppocrv6_tiny_rec.onnx` | Text recognition model. |
| `AppBundle/Resources/OCR/ppocrv6_tiny_det.yml` | Detection metadata. |
| `AppBundle/Resources/OCR/ppocrv6_tiny_rec.yml` | Recognition metadata and character dictionary. |

Main code paths:

| Path | Responsibility |
| --- | --- |
| `Sources/Quick/PasteboardReader.swift` | Reads text and image data from `NSPasteboard`. |
| `Sources/QuickCore/ClipboardContent.swift` | Resolves clipboard content and routes text vs image actions. |
| `Sources/QuickOCR/PaddleONNXOCRService.swift` | Loads ONNX models and runs detection plus recognition. |
| `Sources/QuickCore/DBPostProcessor.swift` | Converts detection probability maps into text boxes. |
| `Sources/QuickCore/CTCLabelDecoder.swift` | Decodes recognition logits into text. |
| `Sources/QuickCore/OCRTextLayout.swift` | Orders OCR boxes into readable lines. |
| `Sources/QuickCore/OCRTextNormalizer.swift` | Restores likely Latin spaces for compact OCR output. |

## Verification

Run the full test suite:

```bash
swift test
```

Inspect bundled model input and output names:

```bash
swift run QuickOCRInspect inspect AppBundle/Resources/OCR
```

Run OCR against a local image:

```bash
swift run QuickOCRInspect recognize AppBundle/Resources/OCR /path/to/image.png
```

Build release assets:

```bash
make zip dmg
```

## Current Limits

- OCR quality is aimed at clear screenshots, UI text, and document text.
- Image OCR does not automatically translate recognized text in v0.2.0.
- The first OCR release uses a lightweight Swift DB postprocessor with axis-aligned crops, not full PaddleOCR rotated box postprocessing.
