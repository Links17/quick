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
}
