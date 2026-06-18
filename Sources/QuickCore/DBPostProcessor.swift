import CoreGraphics
import Foundation

public struct OCRTextBox: Equatable, Sendable {
    public let rect: CGRect
    public let score: Float

    public init(rect: CGRect, score: Float) {
        self.rect = rect
        self.score = score
    }
}

public struct DBPostProcessor: Sendable {
    private let threshold: Float
    private let boxThreshold: Float
    private let minArea: Int
    private let expansionRatio: CGFloat

    public init(
        threshold: Float = 0.2,
        boxThreshold: Float = 0.4,
        minArea: Int = 9,
        expansionRatio: CGFloat = 0.12
    ) {
        self.threshold = threshold
        self.boxThreshold = boxThreshold
        self.minArea = minArea
        self.expansionRatio = expansionRatio
    }

    public func extractBoxes(
        probabilities: [Float],
        mapWidth: Int,
        mapHeight: Int,
        imageWidth: Int,
        imageHeight: Int
    ) -> [OCRTextBox] {
        guard mapWidth > 0,
              mapHeight > 0,
              probabilities.count >= mapWidth * mapHeight else {
            return []
        }

        var visited = Array(repeating: false, count: mapWidth * mapHeight)
        var boxes: [OCRTextBox] = []

        for y in 0..<mapHeight {
            for x in 0..<mapWidth {
                let startIndex = y * mapWidth + x
                guard !visited[startIndex], probabilities[startIndex] >= threshold else {
                    continue
                }

                if let component = floodFill(
                    startX: x,
                    startY: y,
                    probabilities: probabilities,
                    mapWidth: mapWidth,
                    mapHeight: mapHeight,
                    visited: &visited
                ),
                    component.area >= minArea,
                    component.score >= boxThreshold {
                    boxes.append(component.toTextBox(
                        mapWidth: mapWidth,
                        mapHeight: mapHeight,
                        imageWidth: imageWidth,
                        imageHeight: imageHeight,
                        expansionRatio: expansionRatio
                    ))
                }
            }
        }

        return boxes.sorted { lhs, rhs in
            if abs(lhs.rect.minY - rhs.rect.minY) > max(lhs.rect.height, rhs.rect.height) * 0.35 {
                return lhs.rect.minY < rhs.rect.minY
            }
            return lhs.rect.minX < rhs.rect.minX
        }
    }

    private func floodFill(
        startX: Int,
        startY: Int,
        probabilities: [Float],
        mapWidth: Int,
        mapHeight: Int,
        visited: inout [Bool]
    ) -> Component? {
        var queue = [(startX, startY)]
        var cursor = 0
        var minX = startX
        var maxX = startX
        var minY = startY
        var maxY = startY
        var scoreSum: Float = 0
        var area = 0

        visited[startY * mapWidth + startX] = true

        while cursor < queue.count {
            let (x, y) = queue[cursor]
            cursor += 1

            let index = y * mapWidth + x
            let value = probabilities[index]
            guard value >= threshold else {
                continue
            }

            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
            scoreSum += value
            area += 1

            for (nextX, nextY) in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)] {
                guard nextX >= 0, nextX < mapWidth, nextY >= 0, nextY < mapHeight else {
                    continue
                }
                let nextIndex = nextY * mapWidth + nextX
                guard !visited[nextIndex], probabilities[nextIndex] >= threshold else {
                    continue
                }
                visited[nextIndex] = true
                queue.append((nextX, nextY))
            }
        }

        guard area > 0 else {
            return nil
        }

        return Component(
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            area: area,
            score: scoreSum / Float(area)
        )
    }
}

private struct Component {
    let minX: Int
    let maxX: Int
    let minY: Int
    let maxY: Int
    let area: Int
    let score: Float

    func toTextBox(
        mapWidth: Int,
        mapHeight: Int,
        imageWidth: Int,
        imageHeight: Int,
        expansionRatio: CGFloat
    ) -> OCRTextBox {
        let scaleX = CGFloat(imageWidth) / CGFloat(mapWidth)
        let scaleY = CGFloat(imageHeight) / CGFloat(mapHeight)
        let x = CGFloat(minX) * scaleX
        let y = CGFloat(minY) * scaleY
        let width = CGFloat(maxX - minX + 1) * scaleX
        let height = CGFloat(maxY - minY + 1) * scaleY

        let expansionX = width * expansionRatio
        let expansionY = height * expansionRatio
        let expanded = CGRect(
            x: max(0, x - expansionX),
            y: max(0, y - expansionY),
            width: min(CGFloat(imageWidth), x + width + expansionX) - max(0, x - expansionX),
            height: min(CGFloat(imageHeight), y + height + expansionY) - max(0, y - expansionY)
        )

        return OCRTextBox(rect: expanded.integral, score: score)
    }
}
