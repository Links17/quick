import CoreGraphics
import XCTest
@testable import QuickCore

final class DBPostProcessorTests: XCTestCase {
    func testExtractsSortedBoxesFromProbabilityMap() {
        var values = Array(repeating: Float(0.0), count: 12 * 16)
        fill(&values, width: 16, x: 9...13, y: 7...9, value: 0.92)
        fill(&values, width: 16, x: 2...6, y: 2...4, value: 0.88)

        let boxes = DBPostProcessor(
            threshold: 0.2,
            boxThreshold: 0.4,
            minArea: 4,
            expansionRatio: 0.0
        ).extractBoxes(
            probabilities: values,
            mapWidth: 16,
            mapHeight: 12,
            imageWidth: 160,
            imageHeight: 120
        )

        XCTAssertEqual(boxes.map(\.rect), [
            CGRect(x: 20, y: 20, width: 50, height: 30),
            CGRect(x: 90, y: 70, width: 50, height: 30),
        ])
    }

    func testFiltersLowScoreComponents() {
        var values = Array(repeating: Float(0.0), count: 8 * 8)
        fill(&values, width: 8, x: 1...5, y: 1...5, value: 0.25)

        let boxes = DBPostProcessor(
            threshold: 0.2,
            boxThreshold: 0.4,
            minArea: 4,
            expansionRatio: 0.0
        ).extractBoxes(
            probabilities: values,
            mapWidth: 8,
            mapHeight: 8,
            imageWidth: 80,
            imageHeight: 80
        )

        XCTAssertTrue(boxes.isEmpty)
    }

    private func fill(
        _ values: inout [Float],
        width: Int,
        x xRange: ClosedRange<Int>,
        y yRange: ClosedRange<Int>,
        value: Float
    ) {
        for y in yRange {
            for x in xRange {
                values[y * width + x] = value
            }
        }
    }
}
