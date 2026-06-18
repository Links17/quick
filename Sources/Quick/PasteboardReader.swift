import AppKit
import QuickCore

struct PasteboardReader {
    func changeCount() -> Int {
        NSPasteboard.general.changeCount
    }

    func readString() -> String {
        NSPasteboard.general.string(forType: .string) ?? ""
    }

    func readContent() -> ClipboardContent {
        if let value = NSPasteboard.general.string(forType: .string),
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .text(value)
        }

        if let imageData = readImageData() {
            return .imageData(imageData)
        }

        return .text("")
    }

    private func readImageData() -> Data? {
        let pasteboard = NSPasteboard.general

        if let pngData = pasteboard.data(forType: .png), !pngData.isEmpty {
            return pngData
        }

        if let tiffData = pasteboard.data(forType: .tiff), !tiffData.isEmpty {
            return tiffData
        }

        if let images = pasteboard.readObjects(forClasses: [NSImage.self]),
           let image = images.compactMap({ $0 as? NSImage }).first,
           let tiffData = image.tiffRepresentation,
           !tiffData.isEmpty {
            return tiffData
        }

        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let imageURL = fileURLs.first(where: isImageURL),
           let data = try? Data(contentsOf: imageURL),
           !data.isEmpty {
            return data
        }

        return nil
    }

    private func isImageURL(_ url: URL) -> Bool {
        ["png", "jpg", "jpeg", "tiff", "tif", "bmp", "gif", "heic", "webp"].contains(
            url.pathExtension.lowercased()
        )
    }
}
