import XCTest
@testable import QuickCore

final class CTCLabelDecoderTests: XCTestCase {
    func testDecodesIndicesBySkippingBlankAndRepeatedCharacters() {
        let decoder = CTCLabelDecoder(characterDictionary: ["a", "b", "你"])

        let text = decoder.decode(indices: [0, 1, 1, 0, 2, 0, 3, 3])

        XCTAssertEqual(text, "ab你")
    }

    func testDecodesBestPathFromLogits() {
        let decoder = CTCLabelDecoder(characterDictionary: ["a", "b"])
        let logits: [[Float]] = [
            [0.9, 0.1, 0.0],
            [0.1, 0.8, 0.1],
            [0.1, 0.7, 0.2],
            [0.8, 0.1, 0.1],
            [0.1, 0.2, 0.7],
        ]

        let text = decoder.decode(logits: logits)

        XCTAssertEqual(text, "ab")
    }

    func testDecodesLongBlankRunsAsSpaces() {
        let decoder = CTCLabelDecoder(characterDictionary: ["a", "b"])

        let text = decoder.decode(
            indices: [1, 1, 0, 2, 2, 0, 0, 0, 1],
            spaceBlankRunThreshold: 3
        )

        XCTAssertEqual(text, "ab a")
    }

    func testDoesNotInsertSpacesForLeadingOrTrailingBlankRuns() {
        let decoder = CTCLabelDecoder(characterDictionary: ["a", "b"])

        let text = decoder.decode(
            indices: [0, 0, 0, 1, 0, 0, 0],
            spaceBlankRunThreshold: 3
        )

        XCTAssertEqual(text, "a")
    }
}
