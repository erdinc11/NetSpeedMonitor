import AppKit

func createIcon(emoji: String, outputPath: String) {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    
    // Apple standard icon squircle grid (824x824 inside 1024x1024)
    let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let cornerRadius: CGFloat = 185.0
    let path = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // Drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 45, color: NSColor(calibratedWhite: 0, alpha: 0.35).cgColor)
    ctx.addPath(path)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()
    
    // Clip to squircle for gradient
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    
    // Vibrant Blue Gradient: #0284C7 to #1D4ED8
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor(calibratedRed: 0.05, green: 0.55, blue: 0.95, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.12, green: 0.28, blue: 0.85, alpha: 1.0).cgColor
    ] as CFArray
    let locations: [CGFloat] = [0.0, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    }
    
    // Inner border highlight
    ctx.setLineWidth(5.0)
    ctx.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.3).cgColor)
    ctx.addPath(path)
    ctx.strokePath()
    ctx.restoreGState()
    
    // Draw Emoji
    let font = NSFont.systemFont(ofSize: 440)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .paragraphStyle: paragraphStyle
    ]
    let str = NSAttributedString(string: emoji, attributes: attrs)
    let strSize = str.size()
    
    let textRect = CGRect(
        x: (1024 - strSize.width) / 2.0,
        y: (1024 - strSize.height) / 2.0 + 20,
        width: strSize.width,
        height: strSize.height
    )
    str.draw(in: textRect)
    
    image.unlockFocus()
    
    if let tiff = image.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: outputPath))
    }
}

createIcon(emoji: "⚡", outputPath: "/tmp/icon_1024.png")
