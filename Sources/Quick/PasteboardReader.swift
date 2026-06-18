import AppKit

struct PasteboardReader {
    func changeCount() -> Int {
        NSPasteboard.general.changeCount
    }

    func readString() -> String {
        NSPasteboard.general.string(forType: .string) ?? ""
    }
}
