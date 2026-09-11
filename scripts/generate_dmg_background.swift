import AppKit
import CoreGraphics

func generateDMGBackground(outputPath: String) {
    let width = 540
    let height = 380
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Failed to create CGContext")
    }
    
    // Antialiasing
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    
    // Background fill (pure white #FFFFFF)
    ctx.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    // Wrap CGContext into NSGraphicsContext to use NSAttributedString
    NSGraphicsContext.saveGraphicsState()
    let nsc = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.current = nsc
    
    // Title at the top:
    // Window is 380 high.
    // Title positioned nicely in top header: Y in flipped=false is 305 to 350
    let titleFont = NSFont.systemFont(ofSize: 34, weight: .light)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 1.0),
        .paragraphStyle: paragraphStyle
    ]
    let titleStr = NSAttributedString(string: "NetSpeedMonitor", attributes: titleAttrs)
    titleStr.draw(in: CGRect(x: 0, y: 305, width: width, height: 45))
    
    NSGraphicsContext.restoreGraphicsState()
    
    // Horizontal divider line: Y = 290
    ctx.setLineWidth(1.0)
    ctx.setStrokeColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
    ctx.move(to: CGPoint(x: 30, y: 290))
    ctx.addLine(to: CGPoint(x: width - 30, y: 290))
    ctx.strokePath()
    
    // Central Arrow: pointing to the right
    // App icon center: (140, 200 from top) => Cocoa Y = 180
    // Applications drop link center: (400, 200 from top) => Cocoa Y = 180
    let arrowCenterY: CGFloat = 180
    let arrowLeftX: CGFloat = 240
    let arrowRightX: CGFloat = 300
    
    ctx.setLineWidth(2.5)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setStrokeColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1.0)
    
    // Shaft
    ctx.move(to: CGPoint(x: arrowLeftX, y: arrowCenterY))
    ctx.addLine(to: CGPoint(x: arrowRightX, y: arrowCenterY))
    
    // Arrowhead: >
    let headLen: CGFloat = 18.0
    let headHeight: CGFloat = 14.0
    ctx.addLine(to: CGPoint(x: arrowRightX - headLen, y: arrowCenterY + headHeight))
    ctx.move(to: CGPoint(x: arrowRightX, y: arrowCenterY))
    ctx.addLine(to: CGPoint(x: arrowRightX - headLen, y: arrowCenterY - headHeight))
    ctx.strokePath()
    
    guard let cgImage = ctx.makeImage() else {
        fatalError("Failed to create image from context")
    }
    
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    bitmapRep.size = NSSize(width: width, height: height)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to convert image to PNG")
    }
    
    try? pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Generated pixel-perfect \(width)x\(height) background at \(outputPath)")
}

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/dmg_background.png"
generateDMGBackground(outputPath: output)
