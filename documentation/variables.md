# Variables And Secrets

## Secrets

| Name | Storage | Purpose | Risk |
| --- | --- | --- | --- |
| OpenAI API Key | macOS Keychain | Authenticates OpenAI-compatible API calls. | Grants access to configured provider account. |

## Local Settings

| Name | Storage | Purpose |
| --- | --- | --- |
| Base URL | UserDefaults | OpenAI-compatible API root or endpoint. |
| Model | UserDefaults | Provider model name. |
| System Prompt | UserDefaults | Translation behavior instruction sent as `instructions`. |
| Double-copy interval | UserDefaults | Timing window for `cmd+c+c`. |
| Custom shortcut settings | UserDefaults | Optional shortcut configuration. |

## Bundled Model Assets

| Name | Location | Purpose |
| --- | --- | --- |
| `ppocrv6_tiny_det.onnx` | App bundle resources | Local text detection for copied images. |
| `ppocrv6_tiny_rec.onnx` | App bundle resources | Local text recognition for detected image crops. |
| `ppocrv6_tiny_det.yml` / `ppocrv6_tiny_rec.yml` | App bundle resources | PaddleOCR preprocessing/postprocessing metadata and character dictionary. |

## Runtime Notes

The local `.app` bundle built by `make app` is unsigned. macOS may ask for Keychain or privacy permission again after rebuilds because the binary identity changes.
