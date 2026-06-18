import Foundation

public enum PaddleOCRCharacterDictionary {
    public static func parse(_ yaml: String) throws -> [String] {
        var isInDictionary = false
        var characters: [String] = []

        for rawLine in yaml.components(separatedBy: .newlines) {
            let trimmed = rawLine.trimmingCharacters(in: .yamlIndentation)

            if trimmed == "character_dict:" {
                isInDictionary = true
                continue
            }

            guard isInDictionary else {
                continue
            }

            guard trimmed.hasPrefix("- ") else {
                if !trimmed.isEmpty {
                    break
                }
                continue
            }

            let value = String(trimmed.dropFirst(2))
            characters.append(unquote(value))
        }

        guard !characters.isEmpty else {
            throw OCRError.missingCharacterDictionary
        }
        return characters
    }

    private static func unquote(_ value: String) -> String {
        if value.hasPrefix("'"), value.hasSuffix("'"), value.count >= 2 {
            return String(value.dropFirst().dropLast())
        }
        if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}

private extension CharacterSet {
    static let yamlIndentation = CharacterSet(charactersIn: " \t\r")
}
