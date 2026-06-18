import AppKit

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "/tmp/quick-demo-frames")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let canvas = NSSize(width: 960, height: 600)
let frameCount = 72

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func drawRounded(_ rect: NSRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func drawText(_ text: String, in rect: NSRect, size: CGFloat, weight: NSFont.Weight = .regular, color textColor: NSColor, alignment: NSTextAlignment = .left) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineSpacing = 5
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: textColor,
        .paragraphStyle: paragraph,
    ]
    text.draw(in: rect, withAttributes: attributes)
}

func drawMenuBar() {
    drawRounded(NSRect(x: 0, y: 572, width: canvas.width, height: 28), radius: 0, fill: color(0.95, 0.96, 0.95))
    drawText("Q", in: NSRect(x: 842, y: 578, width: 18, height: 16), size: 13, weight: .semibold, color: color(0.35, 0.36, 0.35), alignment: .center)
    drawText("Quick", in: NSRect(x: 26, y: 578, width: 70, height: 16), size: 13, weight: .semibold, color: color(0.13, 0.14, 0.14))
    drawText("9:41", in: NSRect(x: 886, y: 578, width: 42, height: 16), size: 13, color: color(0.13, 0.14, 0.14), alignment: .right)
}

func drawDocumentWindow(selected: Bool) {
    drawRounded(NSRect(x: 70, y: 115, width: 430, height: 360), radius: 12, fill: color(0.99, 0.99, 0.98), stroke: color(0.82, 0.84, 0.82))
    drawRounded(NSRect(x: 70, y: 445, width: 430, height: 30), radius: 12, fill: color(0.91, 0.92, 0.90))
    drawText("Notes", in: NSRect(x: 95, y: 452, width: 120, height: 16), size: 12, weight: .medium, color: color(0.32, 0.34, 0.33))
    drawText("Translate this sentence with Quick.", in: NSRect(x: 105, y: 360, width: 300, height: 28), size: 20, weight: .medium, color: color(0.12, 0.13, 0.14))
    if selected {
        drawRounded(NSRect(x: 100, y: 352, width: 338, height: 36), radius: 5, fill: color(0.50, 0.67, 0.93, 0.36))
        drawText("Translate this sentence with Quick.", in: NSRect(x: 105, y: 360, width: 330, height: 28), size: 20, weight: .medium, color: color(0.05, 0.12, 0.22))
    }
    drawText("Quick works from any app. Select text, press cmd+c+c, and keep reading.", in: NSRect(x: 105, y: 280, width: 330, height: 80), size: 16, color: color(0.38, 0.41, 0.40))
}

func drawImageWindow(selected: Bool) {
    drawRounded(NSRect(x: 70, y: 115, width: 430, height: 360), radius: 12, fill: color(0.99, 0.99, 0.98), stroke: color(0.82, 0.84, 0.82))
    drawRounded(NSRect(x: 70, y: 445, width: 430, height: 30), radius: 12, fill: color(0.91, 0.92, 0.90))
    drawText("Screenshot", in: NSRect(x: 95, y: 452, width: 120, height: 16), size: 12, weight: .medium, color: color(0.32, 0.34, 0.33))
    drawRounded(NSRect(x: 110, y: 245, width: 340, height: 130), radius: 10, fill: color(0.11, 0.12, 0.13))
    drawText("复制图片也可以", in: NSRect(x: 140, y: 315, width: 280, height: 30), size: 24, weight: .semibold, color: color(0.94, 0.96, 0.94), alignment: .center)
    drawText("Quick runs local OCR", in: NSRect(x: 140, y: 280, width: 280, height: 24), size: 18, weight: .medium, color: color(0.70, 0.84, 0.74), alignment: .center)
    if selected {
        drawRounded(NSRect(x: 104, y: 239, width: 352, height: 142), radius: 12, fill: .clear, stroke: color(0.35, 0.56, 0.93), lineWidth: 3)
    }
}

func drawShortcut(_ progress: Int) {
    drawRounded(NSRect(x: 360, y: 506, width: 240, height: 46), radius: 12, fill: color(0.11, 0.12, 0.13, 0.92))
    let text = progress == 0 ? "cmd+c" : "cmd+c+c"
    drawText(text, in: NSRect(x: 380, y: 518, width: 200, height: 20), size: 18, weight: .semibold, color: color(0.91, 0.94, 0.91), alignment: .center)
}

func drawPanel(title: String, left: String? = nil, right: String? = nil, body: String? = nil, loading: Bool = false) {
    drawRounded(NSRect(x: 290, y: 180, width: 590, height: 260), radius: 16, fill: color(0.96, 0.97, 0.95, 0.96), stroke: color(0.76, 0.80, 0.76))
    drawText(title, in: NSRect(x: 320, y: 398, width: 250, height: 22), size: 15, weight: .semibold, color: color(0.12, 0.13, 0.14))
    drawRounded(NSRect(x: 320, y: 385, width: 530, height: 1), radius: 0, fill: color(0.80, 0.83, 0.80))

    if loading {
        drawText("○", in: NSRect(x: 557, y: 292, width: 60, height: 40), size: 32, weight: .regular, color: color(0.20, 0.44, 0.31), alignment: .center)
        return
    }

    if let left, let right {
        drawText(left, in: NSRect(x: 325, y: 255, width: 225, height: 95), size: 19, weight: .medium, color: color(0.12, 0.13, 0.14))
        drawRounded(NSRect(x: 578, y: 230, width: 2, height: 130), radius: 0, fill: color(0.75, 0.78, 0.75))
        drawText(right, in: NSRect(x: 615, y: 250, width: 220, height: 110), size: 19, weight: .medium, color: color(0.05, 0.29, 0.18))
    } else if let body {
        drawText(body, in: NSRect(x: 330, y: 255, width: 500, height: 95), size: 21, weight: .medium, color: color(0.05, 0.29, 0.18))
    }
}

func save(_ image: NSImage, index: Int) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "QuickDemo", code: 1)
    }
    let url = outputDirectory.appendingPathComponent(String(format: "frame_%03d.png", index))
    try png.write(to: url)
}

for index in 0..<frameCount {
    let image = NSImage(size: canvas)
    image.lockFocus()
    color(0.90, 0.92, 0.89).setFill()
    NSRect(origin: .zero, size: canvas).fill()
    drawMenuBar()

    switch index {
    case 0..<10:
        drawDocumentWindow(selected: true)
    case 10..<16:
        drawDocumentWindow(selected: true)
        drawShortcut(0)
    case 16..<22:
        drawDocumentWindow(selected: true)
        drawShortcut(1)
    case 22..<30:
        drawDocumentWindow(selected: true)
        drawPanel(title: "Translating", loading: true)
    case 30..<44:
        drawDocumentWindow(selected: true)
        drawPanel(
            title: "Translation",
            left: "Translate this sentence with Quick.",
            right: "用 Quick 翻译这句话。"
        )
    case 44..<52:
        drawImageWindow(selected: true)
    case 52..<58:
        drawImageWindow(selected: true)
        drawShortcut(1)
    case 58..<64:
        drawImageWindow(selected: true)
        drawPanel(title: "OCR", loading: true)
    default:
        drawImageWindow(selected: true)
        drawPanel(title: "OCR Result", body: "复制图片也可以\nQuick runs local OCR")
    }

    image.unlockFocus()
    try save(image, index: index)
}
