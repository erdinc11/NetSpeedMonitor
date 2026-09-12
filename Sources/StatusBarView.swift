import AppKit

public enum ArrowStyle: String, CaseIterable {
    case standard = "arrows"     // ↑ and ↓
    case triangle = "triangles"  // ▲ and ▼
    
    public var up: String {
        switch self {
        case .standard: return "↑"
        case .triangle: return "▲"
        }
    }
    
    public var down: String {
        switch self {
        case .standard: return "↓"
        case .triangle: return "▼"
        }
    }
}

public class StatusBarIconRenderer {
    
    public static func formatNumberOnly(_ mb: Double) -> String {
        if mb < 0.05 {
            return "0.0"
        } else if mb < 100.0 {
            return String(format: "%.1f", mb)
        } else {
            return String(format: "%.0f", mb)
        }
    }
    
    public static func formatWatts(_ w: Double) -> String {
        if w < 0.05 {
            return "0.0W"
        } else if w >= 100.0 {
            return String(format: "%.0fW", w)
        } else {
            return String(format: "%.1fW", w)
        }
    }
    
    public static func renderImage(
        uploadMB: Double,
        downloadMB: Double,
        powerStats: PowerStats,
        showNetworkSpeed: Bool,
        showPower: Bool,
        arrowStyle: ArrowStyle = .standard
    ) -> NSImage {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .semibold)
        
        let netParagraphStyle = NSMutableParagraphStyle()
        netParagraphStyle.alignment = .right
        
        let netTextAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
            .paragraphStyle: netParagraphStyle
        ]
        
        let powerParagraphStyle = NSMutableParagraphStyle()
        powerParagraphStyle.alignment = .center
        
        let powerTextAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
            .paragraphStyle: powerParagraphStyle
        ]
        
        // 1. Calculate Network Speed width & attributes
        let upAttr: NSAttributedString
        let downAttr: NSAttributedString
        let netWidth: CGFloat
        if showNetworkSpeed {
            let uploadText = "\(formatNumberOnly(uploadMB)) \(arrowStyle.up)"
            let downloadText = "\(formatNumberOnly(downloadMB)) \(arrowStyle.down)"
            upAttr = NSAttributedString(string: uploadText, attributes: netTextAttributes)
            downAttr = NSAttributedString(string: downloadText, attributes: netTextAttributes)
            let maxNetTextWidth = max(upAttr.size().width, downAttr.size().width)
            netWidth = max(ceil(maxNetTextWidth) + 4.0, 34.0)
        } else {
            upAttr = NSAttributedString()
            downAttr = NSAttributedString()
            netWidth = 0.0
        }
        
        // 2. Calculate Power width & attributes
        let wattAttr: NSAttributedString
        let powerWidth: CGFloat
        if showPower {
            let wattText = formatWatts(powerStats.activeWatts)
            wattAttr = NSAttributedString(string: wattText, attributes: powerTextAttributes)
            let wattTextWidth = wattAttr.size().width
            powerWidth = max(ceil(wattTextWidth) + 5.0, 26.0)
        } else {
            wattAttr = NSAttributedString()
            powerWidth = 0.0
        }
        
        let spacing: CGFloat = (showNetworkSpeed && showPower) ? 5.0 : 0.0
        let totalWidth = max(netWidth + spacing + powerWidth, 24.0)
        let totalHeight: CGFloat = 22.0
        
        let image = NSImage(size: NSSize(width: totalWidth, height: totalHeight), flipped: true) { rect in
            var currentX: CGFloat = 1.0
            
            // Draw Network Speed indicator
            if showNetworkSpeed {
                let upRect = NSRect(x: currentX, y: 1.0, width: netWidth - 3.0, height: 10.0)
                upAttr.draw(in: upRect)
                
                let downRect = NSRect(x: currentX, y: 11.0, width: netWidth - 3.0, height: 10.0)
                downAttr.draw(in: downRect)
                
                currentX += netWidth + spacing
            }
            
            // Draw Power indicator
            if showPower {
                let pCenter = currentX + (powerWidth - 3.0) / 2.0
                
                // Top line: Lightning bolt (when charging) or Battery icon (when discharging / idle)
                if powerStats.isCharging {
                    // Draw vector lightning bolt centered at pCenter, y from 1.0 to 11.0
                    let bx = pCenter
                    let by: CGFloat = 1.0
                    let bolt = NSBezierPath()
                    bolt.move(to: NSPoint(x: bx + 0.5, y: by + 0.5))
                    bolt.line(to: NSPoint(x: bx - 3.5, y: by + 5.5))
                    bolt.line(to: NSPoint(x: bx - 0.5, y: by + 5.5))
                    bolt.line(to: NSPoint(x: bx - 1.5, y: by + 10.0))
                    bolt.line(to: NSPoint(x: bx + 3.5, y: by + 5.0))
                    bolt.line(to: NSPoint(x: bx + 0.5, y: by + 5.0))
                    bolt.close()
                    NSColor.black.setFill()
                    bolt.fill()
                } else {
                    // Draw vector battery icon with percentage level fill
                    let bw: CGFloat = 14.0
                    let bh: CGFloat = 7.5
                    let bx = pCenter - bw / 2.0
                    let by: CGFloat = 2.2
                    
                    // Battery body outline
                    let bodyRect = NSRect(x: bx, y: by, width: bw - 2.0, height: bh)
                    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 1.5, yRadius: 1.5)
                    bodyPath.lineWidth = 1.2
                    NSColor.black.setStroke()
                    bodyPath.stroke()
                    
                    // Battery positive cap
                    let capRect = NSRect(x: bx + bw - 1.5, y: by + 2.0, width: 1.5, height: 3.4)
                    let capPath = NSBezierPath(roundedRect: capRect, xRadius: 0.5, yRadius: 0.5)
                    NSColor.black.setFill()
                    capPath.fill()
                    
                    // Battery internal fill
                    let fillPercent = max(0.1, min(1.0, CGFloat(powerStats.batteryLevel) / 100.0))
                    let fillMargin: CGFloat = 1.6
                    let maxFillWidth = (bw - 2.0) - (fillMargin * 2.0)
                    let fillRect = NSRect(
                        x: bx + fillMargin,
                        y: by + fillMargin,
                        width: max(maxFillWidth * fillPercent, 1.2),
                        height: bh - (fillMargin * 2.0)
                    )
                    let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 0.8, yRadius: 0.8)
                    NSColor.black.setFill()
                    fillPath.fill()
                }
                
                // Bottom line: Wattage text (centered under icon)
                let wattRect = NSRect(x: currentX, y: 11.0, width: powerWidth - 3.0, height: 10.0)
                wattAttr.draw(in: wattRect)
            }
            
            return true
        }
        
        image.isTemplate = true
        return image
    }
}
