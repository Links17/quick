import Foundation

public enum OCRTextNormalizer {
    public static func restoreLikelyLatinSpaces(_ text: String) -> String {
        var result = ""
        let characters = Array(text)

        for index in characters.indices {
            let current = characters[index]
            if index > characters.startIndex {
                if shouldInsertSpace(before: index, in: characters),
                   !result.hasSuffix(" "),
                   !result.hasSuffix("\n") {
                    result.append(" ")
                }
            }
            result.append(current)
        }

        return result
    }

    private static func shouldInsertSpace(before index: Int, in characters: [Character]) -> Bool {
        let lhs = characters[index - 1]
        let rhs = characters[index]
        let next = index + 1 < characters.count ? characters[index + 1] : nil

        if lhs.isLowercaseLatin && rhs.isUppercaseLatin {
            return true
        }

        if lhs.isUppercaseLatin && rhs.isUppercaseLatin && next?.isLowercaseLatin == true {
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
