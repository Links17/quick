import CoreGraphics
import Foundation

public struct OCRTextItem: Equatable, Sendable {
    public let text: String
    public let box: OCRTextBox

    public init(text: String, box: OCRTextBox) {
        self.text = text
        self.box = box
    }
}

public enum OCRTextLayout {
    public static func format(_ items: [OCRTextItem]) -> String {
        let nonEmptyItems = items.compactMap { item -> OCRTextItem? in
            let text = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                return nil
            }
            return OCRTextItem(text: text, box: item.box)
        }

        var lines: [[OCRTextItem]] = []
        for item in nonEmptyItems.sorted(by: readingOrder) {
            if let lineIndex = lines.firstIndex(where: { belongsToSameLine(item, $0) }) {
                lines[lineIndex].append(item)
            } else {
                lines.append([item])
            }
        }

        return lines
            .map { line in
                formatLine(line.sorted { $0.box.rect.minX < $1.box.rect.minX })
            }
            .joined(separator: "\n")
    }

    private static func readingOrder(_ lhs: OCRTextItem, _ rhs: OCRTextItem) -> Bool {
        if abs(lhs.box.rect.midY - rhs.box.rect.midY) > max(lhs.box.rect.height, rhs.box.rect.height) * 0.55 {
            return lhs.box.rect.midY < rhs.box.rect.midY
        }
        return lhs.box.rect.minX < rhs.box.rect.minX
    }

    private static func belongsToSameLine(_ item: OCRTextItem, _ line: [OCRTextItem]) -> Bool {
        guard let first = line.first else {
            return false
        }

        let averageHeight = line.reduce(first.box.rect.height) { total, next in
            total + next.box.rect.height
        } / CGFloat(line.count + 1)
        return abs(item.box.rect.midY - first.box.rect.midY) <= averageHeight * 0.65
    }

    private static func formatLine(_ line: [OCRTextItem]) -> String {
        var result = ""
        var previous: OCRTextItem?

        for item in line {
            if let previous {
                let gap = item.box.rect.minX - previous.box.rect.maxX
                let referenceHeight = max(previous.box.rect.height, item.box.rect.height)
                if gap > referenceHeight * 0.22 {
                    result += " "
                }
            }
            result += item.text
            previous = item
        }

        return result
    }
}
