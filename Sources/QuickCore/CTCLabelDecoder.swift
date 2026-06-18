import Foundation

public struct CTCLabelDecoder: Sendable {
    private let characters: [String]

    public init(characterDictionary: [String]) {
        self.characters = [""] + characterDictionary
    }

    public func decode(logits: [[Float]]) -> String {
        let indices = logits.map { row in
            row.enumerated().max { lhs, rhs in
                lhs.element < rhs.element
            }?.offset ?? 0
        }
        return decode(indices: indices)
    }

    public func decode(logits: [[Float]], spaceBlankRunThreshold: Int) -> String {
        let indices = logits.map { row in
            row.enumerated().max { lhs, rhs in
                lhs.element < rhs.element
            }?.offset ?? 0
        }
        return decode(indices: indices, spaceBlankRunThreshold: spaceBlankRunThreshold)
    }

    public func decode(indices: [Int]) -> String {
        var result = ""
        var previousIndex: Int?

        for index in indices {
            defer {
                previousIndex = index
            }

            guard index != 0, index != previousIndex, characters.indices.contains(index) else {
                continue
            }
            result += characters[index]
        }

        return result
    }

    public func decode(indices: [Int], spaceBlankRunThreshold: Int) -> String {
        guard spaceBlankRunThreshold > 0 else {
            return decode(indices: indices)
        }

        var result = ""
        var previousIndex: Int?
        var blankRunLength = 0

        for index in indices {
            if index == 0 {
                blankRunLength += 1
                previousIndex = index
                continue
            }

            if blankRunLength >= spaceBlankRunThreshold,
               !result.isEmpty,
               !result.hasSuffix(" ") {
                result += " "
            }
            blankRunLength = 0

            defer {
                previousIndex = index
            }

            guard index != previousIndex, characters.indices.contains(index) else {
                continue
            }
            result += characters[index]
        }

        return result.trimmingCharacters(in: .whitespaces)
    }
}
