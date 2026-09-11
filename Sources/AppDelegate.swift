import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let networkMonitor = NetworkMonitor()
    private let menu = NSMenu()
    
    // Dynamic menu items
    private var headerItem: NSMenuItem!
    private var downloadDetailItem: NSMenuItem!
    private var uploadDetailItem: NSMenuItem!
    private var totalDownloadItem: NSMenuItem!
    private var totalUploadItem: NSMenuItem!
    private var interfaceItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!
    
    private var lastStats = BandwidthStats()
    private var arrowStyle: ArrowStyle = {
        if let saved = UserDefaults.standard.string(forKey: "ArrowStyle"),
           let style = ArrowStyle(rawValue: saved) {
            return style
        }
        return .standard
    }()
    
    private var arrowStyleSubmenuItem: NSMenuItem!
    private var arrowClassicItem: NSMenuItem!
    private var arrowTriangleItem: NSMenuItem!
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
        
        setupMenu()
        updateStats()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func setupMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
        
        // 1. User specified header: "download=10mb, upload=5mb"
        headerItem = NSMenuItem(title: "download=0mb, upload=0mb", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        let boldFont = NSFont.boldSystemFont(ofSize: 13)
        headerItem.attributedTitle = NSAttributedString(
            string: "download=0mb, upload=0mb",
            attributes: [.font: boldFont, .foregroundColor: NSColor.labelColor]
        )
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Detailed speeds
        downloadDetailItem = NSMenuItem(title: "⬇️ İndirme: 0.00 MB/s", action: nil, keyEquivalent: "")
        downloadDetailItem.isEnabled = false
        menu.addItem(downloadDetailItem)
        
        uploadDetailItem = NSMenuItem(title: "⬆️ Yükleme: 0.00 MB/s", action: nil, keyEquivalent: "")
        uploadDetailItem.isEnabled = false
        menu.addItem(uploadDetailItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Session totals
        totalDownloadItem = NSMenuItem(title: "📥 Toplam İndirilen: 0 MB", action: nil, keyEquivalent: "")
        totalDownloadItem.isEnabled = false
        menu.addItem(totalDownloadItem)
        
        totalUploadItem = NSMenuItem(title: "📤 Toplam Yüklenen: 0 MB", action: nil, keyEquivalent: "")
        totalUploadItem.isEnabled = false
        menu.addItem(totalUploadItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Network interface information
        interfaceItem = NSMenuItem(title: "🌐 Ağ: Bekleniyor...", action: nil, keyEquivalent: "")
        interfaceItem.isEnabled = false
        menu.addItem(interfaceItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Arrow style selector
        arrowStyleSubmenuItem = NSMenuItem(title: "Ok Stili (Tray İkon)", action: nil, keyEquivalent: "")
        let arrowMenu = NSMenu()
        arrowMenu.autoenablesItems = false
        
        arrowClassicItem = NSMenuItem(title: "↑ ↓ Klasik Ok", action: #selector(setArrowStyleClassic), keyEquivalent: "")
        arrowClassicItem.target = self
        arrowMenu.addItem(arrowClassicItem)
        
        arrowTriangleItem = NSMenuItem(title: "▲ ▼ Üçgen Ok", action: #selector(setArrowStyleTriangle), keyEquivalent: "")
        arrowTriangleItem.target = self
        arrowMenu.addItem(arrowTriangleItem)
        
        arrowStyleSubmenuItem.submenu = arrowMenu
        menu.addItem(arrowStyleSubmenuItem)
        
        // Reset totals
        let resetItem = NSMenuItem(title: "🔄 İstatistikleri Sıfırla", action: #selector(resetTotalsClicked), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)
        
        // Launch at login
        launchAtLoginItem = NSMenuItem(title: "🚀 Başlangıçta Otomatik Çalıştır", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "❌ Çıkış (Quit)", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        updateStats()
        updateMenuItems()
        sender.isHighlighted = true
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        updateStats()
        updateMenuItems()
    }
    
    public func menuDidClose(_ menu: NSMenu) {
        statusItem.button?.isHighlighted = false
    }
    
    private func updateStats() {
        let stats = networkMonitor.sample()
        lastStats = stats
        
        // Render dynamic tray icon with up arrow for upload and down arrow for download
        let iconImage = StatusBarIconRenderer.renderImage(
            uploadMB: stats.uploadSpeedMB,
            downloadMB: stats.downloadSpeedMB,
            arrowStyle: arrowStyle
        )
        statusItem.button?.image = iconImage
    }
    
    private func formatTotalBytes(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0
        
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.0f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }
    
    private func formatHeaderSpeed(_ mb: Double) -> String {
        if mb < 0.05 {
            return "0"
        } else if mb >= 10.0 {
            return String(format: "%.0f", mb)
        } else {
            let s = String(format: "%.1f", mb)
            return s.hasSuffix(".0") ? String(format: "%.0f", mb) : s
        }
    }
    
    private func updateMenuItems() {
        let downFormatted = formatHeaderSpeed(lastStats.downloadSpeedMB)
        let upFormatted = formatHeaderSpeed(lastStats.uploadSpeedMB)
        
        // Exact user requirement: "download=10mb, upload=5mb"
        let headerText = "download=\(downFormatted)mb, upload=\(upFormatted)mb"
        let boldFont = NSFont.boldSystemFont(ofSize: 13)
        headerItem.attributedTitle = NSAttributedString(
            string: headerText,
            attributes: [.font: boldFont, .foregroundColor: NSColor.labelColor]
        )
        
        downloadDetailItem.title = String(format: "⬇️ İndirme Hızı: %.2f MB/s", lastStats.downloadSpeedMB)
        uploadDetailItem.title = String(format: "⬆️ Yükleme Hızı: %.2f MB/s", lastStats.uploadSpeedMB)
        
        totalDownloadItem.title = "📥 Toplam İndirilen: \(formatTotalBytes(lastStats.totalDownloadBytes))"
        totalUploadItem.title = "📤 Toplam Yüklenen: \(formatTotalBytes(lastStats.totalUploadBytes))"
        
        let ifaces = lastStats.activeInterfaces.joined(separator: ", ")
        let ifaceText = ifaces.isEmpty ? "Bağlantı Yok" : ifaces
        interfaceItem.title = "🌐 Aktif Ağ: \(ifaceText)"
        
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        arrowClassicItem.state = (arrowStyle == .standard) ? .on : .off
        arrowTriangleItem.state = (arrowStyle == .triangle) ? .on : .off
    }
    
    @objc private func setArrowStyleClassic() {
        arrowStyle = .standard
        UserDefaults.standard.set(arrowStyle.rawValue, forKey: "ArrowStyle")
        updateStats()
        updateMenuItems()
    }
    
    @objc private func setArrowStyleTriangle() {
        arrowStyle = .triangle
        UserDefaults.standard.set(arrowStyle.rawValue, forKey: "ArrowStyle")
        updateStats()
        updateMenuItems()
    }
    
    @objc private func resetTotalsClicked() {
        networkMonitor.resetTotals()
        updateStats()
        updateMenuItems()
    }
    
    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Launch at Login (via LaunchAgent)
    private var launchAgentURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/com.user.NetSpeedMonitor.plist")
    }
    
    private func isLaunchAtLoginEnabled() -> Bool {
        return FileManager.default.fileExists(atPath: launchAgentURL.path)
    }
    
    @objc private func toggleLaunchAtLogin() {
        let fileManager = FileManager.default
        if isLaunchAtLoginEnabled() {
            try? fileManager.removeItem(at: launchAgentURL)
        } else {
            let appPath = Bundle.main.bundlePath
            let execPath = Bundle.main.executablePath ?? "\(appPath)/Contents/MacOS/NetSpeedMonitor"
            
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.user.NetSpeedMonitor</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(execPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>KeepAlive</key>
                <false/>
            </dict>
            </plist>
            """
            let dir = launchAgentURL.deletingLastPathComponent()
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            try? plistContent.write(to: launchAgentURL, atomically: true, encoding: .utf8)
        }
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
    }
}
