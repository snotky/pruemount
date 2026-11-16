import AppKit
import CoreGraphics

/// 自動繪製 PureMount macOS 原生圓角圖示並回傳 PNG Data
func renderIconPNG(size: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
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
        return nil
    }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    guard let nsCtx = NSGraphicsContext(bitmapImageRep: rep) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    NSGraphicsContext.current = nsCtx
    let ctx = nsCtx.cgContext

    let cgSize = CGSize(width: size, height: size)
    let rect = CGRect(origin: .zero, size: cgSize)
    let inset = CGFloat(size) * 0.08
    let cardRect = rect.insetBy(dx: inset, dy: inset)
    let cornerRadius = CGFloat(size) * 0.22

    // 1. 繪製深海藍至青綠漸層圓角背景
    let path = CGPath(roundedRect: cardRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.06, green: 0.45, blue: 0.92, alpha: 1.0),
        CGColor(red: 0.04, green: 0.72, blue: 0.68, alpha: 1.0)
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: cardRect.minX, y: cardRect.maxY),
            end: CGPoint(x: cardRect.maxX, y: cardRect.minY),
            options: []
        )
    }
    ctx.restoreGState()

    // 2. 繪製白色硬碟主體圖形
    let driveWidth = cardRect.width * 0.56
    let driveHeight = cardRect.height * 0.42
    let driveRect = CGRect(
        x: rect.midX - driveWidth / 2,
        y: rect.midY - driveHeight / 2,
        width: driveWidth,
        height: driveHeight
    )
    let drivePath = CGPath(
        roundedRect: driveRect,
        cornerWidth: CGFloat(size) * 0.06,
        cornerHeight: CGFloat(size) * 0.06,
        transform: nil
    )
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.addPath(drivePath)
    ctx.fillPath()

    // 3. 硬碟讀寫指示綠燈
    let dotRadius = CGFloat(size) * 0.032
    let dotCenter = CGPoint(
        x: driveRect.maxX - CGFloat(size) * 0.08,
        y: driveRect.minY + CGFloat(size) * 0.08
    )
    ctx.setFillColor(CGColor(red: 0.12, green: 0.82, blue: 0.45, alpha: 1.0))
    ctx.fillEllipse(in: CGRect(
        x: dotCenter.x - dotRadius,
        y: dotCenter.y - dotRadius,
        width: dotRadius * 2,
        height: dotRadius * 2
    ))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

func appendUInt32BE(_ value: UInt32, to data: inout Data) {
    var be = value.bigEndian
    data.append(Data(bytes: &be, count: 4))
}

/// 直接封裝符合 Apple 規範的 .icns 二進位檔案
func writeICNS(to outputPath: String) {
    let chunks: [(String, Int)] = [
        ("ic07", 128),
        ("ic08", 256),
        ("ic09", 512),
        ("ic10", 1024)
    ]

    var bodyData = Data()
    for (tag, size) in chunks {
        guard let png = renderIconPNG(size: size) else { continue }
        bodyData.append(contentsOf: tag.utf8)
        appendUInt32BE(UInt32(8 + png.count), to: &bodyData)
        bodyData.append(png)
    }

    var fileData = Data()
    fileData.append(contentsOf: "icns".utf8)
    appendUInt32BE(UInt32(8 + bodyData.count), to: &fileData)
    fileData.append(bodyData)

    try? fileData.write(to: URL(fileURLWithPath: outputPath))
}

let args = CommandLine.arguments
if args.count >= 2 {
    writeICNS(to: args[1])
}
