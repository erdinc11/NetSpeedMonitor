import AppKit

func generateDMGBackground(outputPath: String) {
    let width: CGFloat = 540
    let height: CGFloat = 380
    let scale: CGFloat = 2.0 // 2x Retina
    
    let size = NSSize(width: width * scale, height: height * scale)
    let image = NSImage(size: size)
    
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    
    ctx.scaleBy(x: scale, y: scale)
    
    // Background fill (white)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    // In Cocoa flipped=false coordinates: (0,0) is bottom-left, y=380 is top
    // Title at the top: y from top is ~45px => Cocoa Y = 380 - 45 - 35 = 300
    let titleFont = NSFont.systemFont(ofSize: 34, weight: .light)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 1.0),
        .paragraphStyle: paragraphStyle
    ]
    let titleStr = NSAttributedString(string: "NetSpeedMonitor", attributes: titleAttrs)
    titleStr.draw(in: CGRect(x: 0, y: 310, width: width, height: 45))
    
    // Horizontal divider line at y = 92px from top => Cocoa Y = 380 - 92 = 288
    ctx.setLineWidth(1.0)
    ctx.setStrokeColor(NSColor(calibratedWhite: 0.88, alpha: 1.0).cgColor)
    ctx.move(to: CGPoint(x: 30, y: 288))
    ctx.addLine(to: CGPoint(x: width - 30, y: 288))
    ctx.strokePath()
    
    // Central Arrow: pointing from app icon (x:130) to Applications folder (x:410)
    // Finder icon center is y=200 from top => Cocoa Y = 380 - 200 = 180
    let arrowCenterY: CGFloat = 180
    let arrowLeftX: CGFloat = 245
    let arrowRightX: CGFloat = 295
    
    ctx.setLineWidth(2.5)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setStrokeColor(NSColor(calibratedWhite: 0.55, alpha: 1.0).cgColor)
    
    // Shaft
    ctx.move(to: CGPoint(x: arrowLeftX, y: arrowCenterY))
    ctx.addLine(to: CGPoint(x: arrowRightX, y: arrowCenterY))
    
    // Arrowhead
    let headLength: CGFloat = 16.0
    let headAngle: CGFloat = 13.0
    ctx.addLine(to: CGPoint(x: arrowRightX - headLength, y: arrowCenterY + headAngle))
    ctx.move(to: CGPoint(x: arrowRightX, y: arrowCenterY))
    ctx.addLine(to: CGPoint(x: arrowRightX - headLength, y: arrowCenterY - headAngle))
    ctx.strokePath()
    
    image.unlockFocus()
    
    if let tiff = image.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: outputPath))
        print("Generated background at \(outputPath)")
    }
}

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/dmg_background.png"
generateDMGBackground(outputPath: output)
