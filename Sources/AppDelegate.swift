import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let networkMonitor = NetworkMonitor()
    private let powerMonitor = PowerMonitor()
    private let menu = NSMenu()
    
    // Dynamic network menu items
    private var headerItem: NSMenuItem!
    private var downloadDetailItem: NSMenuItem!
    private var uploadDetailItem: NSMenuItem!
    private var totalDownloadItem: NSMenuItem!
    private var totalUploadItem: NSMenuItem!
    private var interfaceItem: NSMenuItem!
    
    // Dynamic power menu items
    private var powerHeaderItem: NSMenuItem!
    private var powerDetailsItem: NSMenuItem!
    private var powerSourceItem: NSMenuItem!
    private var powerBatteryHealthItem: NSMenuItem!
    
    // Settings & Control items
    private var settingsItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!
    
    private var lastStats = BandwidthStats()
    public private(set) var currentPowerStats = PowerStats()
    
    private var settingsWindowController: SettingsWindowController?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
        
        setupMenu()
        updateStats()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: SettingsManager.didChangeNotification,
            object: nil
        )
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    @objc private func settingsDidChange() {
        updateStats()
        updateMenuItems()
    }
    
    private func setupMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
        
        let boldFont = NSFont.boldSystemFont(ofSize: 13)
        
        // 1. Network Header
        headerItem = NSMenuItem(title: "download=0mb, upload=0mb", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        headerItem.attributedTitle = NSAttributedString(
            string: "download=0mb, upload=0mb",
            attributes: [.font: boldFont, .foregroundColor: NSColor.labelColor]
        )
        menu.addItem(headerItem)
        
        // Detailed speeds
        downloadDetailItem = NSMenuItem(title: "⬇️ Download Speed: 0.00 MB/s", action: nil, keyEquivalent: "")
        downloadDetailItem.isEnabled = false
        menu.addItem(downloadDetailItem)
        
        uploadDetailItem = NSMenuItem(title: "⬆️ Upload Speed: 0.00 MB/s", action: nil, keyEquivalent: "")
        uploadDetailItem.isEnabled = false
        menu.addItem(uploadDetailItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Session totals
        totalDownloadItem = NSMenuItem(title: "📥 Total Downloaded: 0 MB", action: nil, keyEquivalent: "")
        totalDownloadItem.isEnabled = false
        menu.addItem(totalDownloadItem)
        
        totalUploadItem = NSMenuItem(title: "📤 Total Uploaded: 0 MB", action: nil, keyEquivalent: "")
        totalUploadItem.isEnabled = false
        menu.addItem(totalUploadItem)
        
        // Interface
        interfaceItem = NSMenuItem(title: "🌐 Interface: Waiting...", action: nil, keyEquivalent: "")
        interfaceItem.isEnabled = false
        menu.addItem(interfaceItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Power & Battery Section
        powerHeaderItem = NSMenuItem(title: "⚡ Power Status", action: nil, keyEquivalent: "")
        powerHeaderItem.isEnabled = false
        powerHeaderItem.attributedTitle = NSAttributedString(
            string: "⚡ Power Status",
            attributes: [.font: boldFont, .foregroundColor: NSColor.labelColor]
        )
        menu.addItem(powerHeaderItem)
        
        powerDetailsItem = NSMenuItem(title: "⚡ System In: 0.0W | Load: 0.0W", action: nil, keyEquivalent: "")
        powerDetailsItem.isEnabled = false
        menu.addItem(powerDetailsItem)
        
        powerSourceItem = NSMenuItem(title: "🔌 Power Source: Checking...", action: nil, keyEquivalent: "")
        powerSourceItem.isEnabled = false
        menu.addItem(powerSourceItem)
        
        powerBatteryHealthItem = NSMenuItem(title: "🔋 Battery: 100% | 0.0°C", action: nil, keyEquivalent: "")
        powerBatteryHealthItem.isEnabled = false
        menu.addItem(powerBatteryHealthItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Settings Window
        settingsItem = NSMenuItem(title: "⚙️ Settings...", action: #selector(openSettingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // Reset totals
        let resetItem = NSMenuItem(title: "🔄 Reset Statistics", action: #selector(resetTotalsClicked), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)
        
        // Launch at login
        launchAtLoginItem = NSMenuItem(title: "🚀 Launch at Login", action: #selector(toggleLaunchAtLoginClicked), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "❌ Quit", action: #selector(quitClicked), keyEquivalent: "q")
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
        let netStats = networkMonitor.sample()
        let powerStats = powerMonitor.sample()
        
        lastStats = netStats
        currentPowerStats = powerStats
        
        let settings = SettingsManager.shared
        
        // Render dynamic tray icon with requested features
        let iconImage = StatusBarIconRenderer.renderImage(
            uploadMB: netStats.uploadSpeedMB,
            downloadMB: netStats.downloadSpeedMB,
            powerStats: powerStats,
            showNetworkSpeed: settings.showNetworkSpeed,
            showPower: settings.showPower,
            arrowStyle: settings.arrowStyle
        )
        statusItem.button?.image = iconImage
        
        // If settings window is currently visible, keep power preview fresh
        if let win = settingsWindowController?.window, win.isVisible {
            settingsWindowController?.updatePowerPreview(powerStats)
        }
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
        let boldFont = NSFont.boldSystemFont(ofSize: 13)
        
        // 1. Network items
        let downFormatted = formatHeaderSpeed(lastStats.downloadSpeedMB)
        let upFormatted = formatHeaderSpeed(lastStats.uploadSpeedMB)
        let headerText = "download=\(downFormatted)mb, upload=\(upFormatted)mb"
        headerItem.attributedTitle = NSAttributedString(
            string: headerText,
            attributes: [.font: boldFont, .foregroundColor: NSColor.labelColor]
        )
        
        downloadDetailItem.title = String(format: "⬇️ Download Speed: %.2f MB/s", lastStats.downloadSpeedMB)
        uploadDetailItem.title = String(format: "⬆️ Upload Speed: %.2f MB/s", lastStats.uploadSpeedMB)
        
        totalDownloadItem.title = "📥 Total Downloaded: \(formatTotalBytes(lastStats.totalDownloadBytes))"
        totalUploadItem.title = "📤 Total Uploaded: \(formatTotalBytes(lastStats.totalUploadBytes))"
        
        let ifaces = lastStats.activeInterfaces.joined(separator: ", ")
        let ifaceText = ifaces.isEmpty ? "No Connection" : ifaces
        interfaceItem.title = "🌐 Active Interface: \(ifaceText)"
        
        // 2. Power items
        if currentPowerStats.hasBattery {
            let pWatts = StatusBarIconRenderer.formatWatts(currentPowerStats.activeWatts)
            let pHeader: String
            if currentPowerStats.isCharging {
                pHeader = "⚡ Charging: \(pWatts) (\(currentPowerStats.batteryLevel)%)"
            } else if currentPowerStats.isPluggedIn {
                pHeader = "🔌 AC Power: \(pWatts) (Fully Charged \(currentPowerStats.batteryLevel)%)"
            } else {
                pHeader = "🔋 Battery: \(pWatts) Consumed (\(currentPowerStats.batteryLevel)%)"
            }
            powerHeaderItem.attributedTitle = NSAttributedString(
                string: pHeader,
                attributes: [.font: boldFont, .foregroundColor: NSColor.labelColor]
            )
            
            powerDetailsItem.title = String(
                format: "⚡ System In: %.1fW | System Load: %.1fW",
                currentPowerStats.systemInWatts,
                currentPowerStats.systemLoadWatts
            )
            
            let adapterStr = currentPowerStats.adapterWatts > 0 ? "\(currentPowerStats.adapterWatts)W Adapter" : "Connected"
            powerSourceItem.title = currentPowerStats.isPluggedIn ?
                "🔌 Power Source: \(adapterStr)" :
                "🔋 Power Source: Battery"
            
            powerBatteryHealthItem.title = String(
                format: "🔋 Level: %d%% | %.1f°C | %d Cycles",
                currentPowerStats.batteryLevel,
                currentPowerStats.temperature,
                currentPowerStats.cycleCount
            )
        } else {
            powerHeaderItem.attributedTitle = NSAttributedString(
                string: "🔌 AC Power Only (Desktop Mac)",
                attributes: [.font: boldFont, .foregroundColor: NSColor.labelColor]
            )
            powerDetailsItem.title = "⚡ System Load: N/A"
            powerSourceItem.title = "🔌 Power Source: AC Adapter"
            powerBatteryHealthItem.title = "🔋 Battery: Not Present"
        }
        
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
    }
    
    @objc public func openSettingsClicked() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(appDelegate: self)
        }
        settingsWindowController?.showSettings()
    }
    
    @objc private func resetTotalsClicked() {
        resetTotals()
    }
    
    public func resetTotals() {
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
        return home.appendingPathComponent("Library/LaunchAgents/com.erdinc.MacTrayMonitor.plist")
    }
    
    public func isLaunchAtLoginEnabled() -> Bool {
        return FileManager.default.fileExists(atPath: launchAgentURL.path)
    }
    
    @objc private func toggleLaunchAtLoginClicked() {
        toggleLaunchAtLogin()
    }
    
    public func toggleLaunchAtLogin() {
        let fileManager = FileManager.default
        if isLaunchAtLoginEnabled() {
            try? fileManager.removeItem(at: launchAgentURL)
        } else {
            let appPath = Bundle.main.bundlePath
            let execPath = Bundle.main.executablePath ?? "\(appPath)/Contents/MacOS/MacTrayMonitor"
            
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.erdinc.MacTrayMonitor</string>
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
        settingsWindowController?.updateValues()
    }
}
