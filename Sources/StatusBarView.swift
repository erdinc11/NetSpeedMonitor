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
    
    public static func renderImage(uploadMB: Double, downloadMB: Double, arrowStyle: ArrowStyle = .standard) -> NSImage {
        // Upload on top with up arrow on the right
        let uploadText = "\(formatNumberOnly(uploadMB)) \(arrowStyle.up)"
        // Download on bottom with down arrow on the right
        let downloadText = "\(formatNumberOnly(downloadMB)) \(arrowStyle.down)"
        
        let font = NSFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .semibold)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let upAttr = NSAttributedString(string: uploadText, attributes: textAttributes)
        let downAttr = NSAttributedString(string: downloadText, attributes: textAttributes)
        
        let upWidth = upAttr.size().width
        let downWidth = downAttr.size().width
        let maxWidth = max(upWidth, downWidth)
        
        // Fixed minimum width to avoid menu bar icon jumping
        let totalWidth = max(ceil(maxWidth) + 4.0, 34.0)
        let totalHeight: CGFloat = 22.0
        
        let image = NSImage(size: NSSize(width: totalWidth, height: totalHeight), flipped: true) { rect in
            // flipped: true means (0,0) is top-left
            // Upload is on top: y from 1.0 to 11.0
            let upRect = NSRect(x: 1.0, y: 1.0, width: rect.width - 3.0, height: 10.0)
            upAttr.draw(in: upRect)
            
            // Download is on bottom: y from 11.0 to 21.0
            let downRect = NSRect(x: 1.0, y: 11.0, width: rect.width - 3.0, height: 10.0)
            downAttr.draw(in: downRect)
            
            return true
        }
        
        // isTemplate = true lets macOS automatically invert or tint for dark mode / wallpaper
        image.isTemplate = true
        return image
    }
}
