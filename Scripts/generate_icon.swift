import AppKit
import CoreText
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AppBundle")
let iconsetURL = outputDirectory.appendingPathComponent("Quick.iconset", isDirectory: true)
let fileManager = FileManager.default

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func makeGlyphPath(fontSize: CGFloat) -> CGPath {
    let font = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, fontSize, nil)
    var character: UniChar = 81
    var glyph = CGGlyph()
    guard CTFontGetGlyphsForCharacters(font, &character, &glyph, 1),
          let path = CTFontCreatePathForGlyph(font, glyph, nil) else {
        fatalError("Unable to create Q glyph path.")
    }
    return path
}

func centeredPath(_ path: CGPath, in rect: CGRect) -> CGPath {
    let bounds = path.boundingBoxOfPath
    let scale = min(rect.width / bounds.width, rect.height / bounds.height)
    var transform = CGAffineTransform.identity
        .translatedBy(x: rect.midX, y: rect.midY)
        .scaledBy(x: scale, y: -scale)
        .translatedBy(x: -bounds.midX, y: -bounds.midY)
    return path.copy(using: &transform) ?? path
}

func drawQ(
    in rect: CGRect,
    fontSize: CGFloat,
    offset: CGPoint,
    fillColor: NSColor,
    strokeColor: NSColor? = nil,
    strokeWidth: CGFloat = 0
) {
    let font = NSFont(name: "HelveticaNeue-Bold", size: fontSize) ?? .boldSystemFont(ofSize: fontSize)
    var attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: fillColor,
    ]
    if let strokeColor {
        attributes[.strokeColor] = strokeColor
        attributes[.strokeWidth] = strokeWidth
    }

    let value = NSAttributedString(string: "Q", attributes: attributes)
    let size = value.size()
    let origin = CGPoint(
        x: rect.midX - size.width / 2 + offset.x,
        y: rect.midY - size.height / 2 + offset.y
    )
    value.draw(at: origin)
}

func drawIcon(size: Int, name: String) throws {
    let imageSize = NSSize(width: size, height: size)
    guard let representation = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Unable to create bitmap representation.")
    }

    representation.size = imageSize
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)

    guard let context = NSGraphicsContext.current?.cgContext else {
        fatalError("Unable to create graphics context.")
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.clear(CGRect(origin: .zero, size: CGSize(width: size, height: size)))

    let canvas = CGRect(x: 0, y: 0, width: size, height: size)
    let inset = CGFloat(size) * 0.075
    let tile = canvas.insetBy(dx: inset, dy: inset)
    let radius = CGFloat(size) * 0.205

    let tilePath = CGPath(
        roundedRect: tile,
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
    )
    context.addPath(tilePath)
    context.setFillColor(NSColor.white.cgColor)
    context.fillPath()

    context.addPath(tilePath)
    context.setStrokeColor(NSColor.black.withAlphaComponent(0.10).cgColor)
    context.setLineWidth(max(1, CGFloat(size) * 0.006))
    context.strokePath()

    let unit = CGFloat(size)
    drawQ(
        in: canvas,
        fontSize: unit * 0.68,
        offset: CGPoint(x: -unit * 0.040, y: unit * 0.030),
        fillColor: .clear,
        strokeColor: .black,
        strokeWidth: 4
    )
    drawQ(
        in: canvas,
        fontSize: unit * 0.52,
        offset: CGPoint(x: unit * 0.060, y: -unit * 0.042),
        fillColor: .black
    )

    NSGraphicsContext.restoreGraphicsState()

    guard let png = representation.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG.")
    }
    try png.write(to: iconsetURL.appendingPathComponent(name))
}

for icon in iconSizes {
    try drawIcon(size: icon.pixels, name: icon.name)
}
