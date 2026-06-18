import Foundation

public enum OCRTextNormalizer {
    public static func restoreLikelyLatinSpaces(_ text: String) -> String {
        var result = ""
        let characters = Array(text)

        for index in characters.indices {
            let current = characters[index]
            if index > characters.startIndex {
                let previous = characters[characters.index(before: index)]
                if shouldInsertSpace(between: previous, and: current),
                   !result.hasSuffix(" "),
                   !result.hasSuffix("\n") {
                    result.append(" ")
                }
            }
            result.append(current)
        }

        return result
    }

    private static func shouldInsertSpace(between lhs: Character, and rhs: Character) -> Bool {
        if lhs.isLowercaseLatin && rhs.isUppercaseLatin {
            return true
        }

        if lhs.isLatinLetter && rhs.isNumber {
            return true
        }

        if lhs.isNumber && rhs.isLatinLetter {
            return true
        }

        return false
    }
}

private extension Character {
    var isLatinLetter: Bool {
        guard let scalar = unicodeScalars.first, unicodeScalars.count == 1 else {
            return false
        }
        return ("A"..."Z").contains(Character(scalar)) || ("a"..."z").contains(Character(scalar))
    }

    var isLowercaseLatin: Bool {
        guard let scalar = unicodeScalars.first, unicodeScalars.count == 1 else {
            return false
        }
        return ("a"..."z").contains(Character(scalar))
    }

    var isUppercaseLatin: Bool {
        guard let scalar = unicodeScalars.first, unicodeScalars.count == 1 else {
            return false
        }
        return ("A"..."Z").contains(Character(scalar))
    }
}
