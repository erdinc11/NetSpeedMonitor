import AppKit

public class SettingsWindowController: NSWindowController, NSWindowDelegate {
    
    private var showNetworkCheckbox: NSButton!
    private var showPowerCheckbox: NSButton!
    private var arrowClassicRadio: NSButton!
    private var arrowTriangleRadio: NSButton!
    private var launchAtLoginCheckbox: NSButton!
    private var powerInfoLabel: NSTextField!
    
    private weak var appDelegate: AppDelegate?
    
    public init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacTrayMonitor Settings"
        window.center()
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
        window.delegate = self
        setupUI()
        updateValues()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let window = window else { return }
        
        let container = NSView(frame: window.contentView!.bounds)
        container.autoresizingMask = [.width, .height]
        window.contentView = container
        
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
        container.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
        
        // 1. Header with App Title
        let headerBox = NSStackView()
        headerBox.orientation = .horizontal
        headerBox.alignment = .centerY
        headerBox.spacing = 12
        
        let titleLabel = NSTextField(labelWithString: "MacTrayMonitor")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        headerBox.addArrangedSubview(titleLabel)
        
        let versionLabel = NSTextField(labelWithString: "v2.0.0")
        versionLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        versionLabel.textColor = .secondaryLabelColor
        headerBox.addArrangedSubview(versionLabel)
        
        mainStack.addArrangedSubview(headerBox)
        
        // Separator
        mainStack.addArrangedSubview(createSeparator())
        
        // 2. Menu Bar Visibility Section
        let visibilityTitle = createSectionTitle("Tray Icon Visibility (Görünürlük)")
        mainStack.addArrangedSubview(visibilityTitle)
        
        showNetworkCheckbox = NSButton(
            checkboxWithTitle: "Show Network Speed (İnternet Hızı: ⬆ / ⬇)",
            target: self,
            action: #selector(showNetworkToggled(_:))
        )
        mainStack.addArrangedSubview(showNetworkCheckbox)
        
        showPowerCheckbox = NSButton(
            checkboxWithTitle: "Show Power & Battery (Güç / Batarya: ⚡ / 🔋)",
            target: self,
            action: #selector(showPowerToggled(_:))
        )
        mainStack.addArrangedSubview(showPowerCheckbox)
        
        let visibilityHint = NSTextField(wrappingLabelWithString: "En az bir göstergenin menü çubuğunda açık kalması gerekir.")
        visibilityHint.font = NSFont.systemFont(ofSize: 11)
        visibilityHint.textColor = .secondaryLabelColor
        mainStack.addArrangedSubview(visibilityHint)
        
        // Separator
        mainStack.addArrangedSubview(createSeparator())
        
        // 3. Arrow Style Section
        let arrowTitle = createSectionTitle("Network Arrow Style (Ok Stili)")
        mainStack.addArrangedSubview(arrowTitle)
        
        let arrowStack = NSStackView()
        arrowStack.orientation = .horizontal
        arrowStack.spacing = 20
        
        arrowClassicRadio = NSButton(
            radioButtonWithTitle: "↑ ↓ Classic Arrows",
            target: self,
            action: #selector(arrowStyleChanged(_:))
        )
        arrowTriangleRadio = NSButton(
            radioButtonWithTitle: "▲ ▼ Solid Triangles",
            target: self,
            action: #selector(arrowStyleChanged(_:))
        )
        arrowStack.addArrangedSubview(arrowClassicRadio)
        arrowStack.addArrangedSubview(arrowTriangleRadio)
        mainStack.addArrangedSubview(arrowStack)
        
        // Separator
        mainStack.addArrangedSubview(createSeparator())
        
        // 4. Power & Battery Status Preview
        let powerTitle = createSectionTitle("Current Power Status (Anlık Durum)")
        mainStack.addArrangedSubview(powerTitle)
        
        powerInfoLabel = NSTextField(wrappingLabelWithString: "Loading power metrics...")
        powerInfoLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        powerInfoLabel.textColor = .labelColor
        mainStack.addArrangedSubview(powerInfoLabel)
        
        // Separator
        mainStack.addArrangedSubview(createSeparator())
        
        // 5. General Section
        let generalTitle = createSectionTitle("General (Genel)")
        mainStack.addArrangedSubview(generalTitle)
        
        launchAtLoginCheckbox = NSButton(
            checkboxWithTitle: "Launch at Login (Açılışta Otomatik Başlat)",
            target: self,
            action: #selector(launchAtLoginToggled(_:))
        )
        mainStack.addArrangedSubview(launchAtLoginCheckbox)
        
        let resetBtn = NSButton(
            title: "Reset Network Totals (İstatistikleri Sıfırla)",
            target: self,
            action: #selector(resetTotalsClicked(_:))
        )
        resetBtn.bezelStyle = .rounded
        mainStack.addArrangedSubview(resetBtn)
    }
    
    private func createSectionTitle(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        return label
    }
    
    private func createSeparator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false
        box.widthAnchor.constraint(equalToConstant: 370).isActive = true
        return box
    }
    
    public func updateValues() {
        let settings = SettingsManager.shared
        showNetworkCheckbox.state = settings.showNetworkSpeed ? .on : .off
        showPowerCheckbox.state = settings.showPower ? .on : .off
        
        arrowClassicRadio.state = (settings.arrowStyle == .standard) ? .on : .off
        arrowTriangleRadio.state = (settings.arrowStyle == .triangle) ? .on : .off
        
        if let appDelegate = appDelegate {
            launchAtLoginCheckbox.state = appDelegate.isLaunchAtLoginEnabled() ? .on : .off
            updatePowerPreview(appDelegate.currentPowerStats)
        }
    }
    
    public func updatePowerPreview(_ stats: PowerStats) {
        if !stats.hasBattery {
            powerInfoLabel.stringValue = "Power Source: AC Power (Desktop Mac - No Battery)"
            return
        }
        
        let stateText = stats.isCharging ? "⚡ Charging (\(String(format: "%.1fW", stats.activeWatts)))" :
                       (stats.isPluggedIn ? "🔌 Connected (Full / AC)" : "🔋 Discharging (\(String(format: "%.1fW", stats.activeWatts)))")
        
        let adapterText = stats.adapterWatts > 0 ? "\(stats.adapterWatts)W Adapter" : "None"
        
        powerInfoLabel.stringValue = """
        • State: \(stateText)
        • Battery Level: \(stats.batteryLevel)%
        • Power Draw: \(String(format: "%.1fW", stats.activeWatts)) (Load: \(String(format: "%.1fW", stats.systemLoadWatts)))
        • Power Adapter: \(adapterText)
        • Temperature: \(String(format: "%.1f°C", stats.temperature)) | Cycles: \(stats.cycleCount)
        """
    }
    
    @objc private func showNetworkToggled(_ sender: NSButton) {
        let wantShow = (sender.state == .on)
        let success = SettingsManager.shared.setShowNetworkSpeed(wantShow)
        if !success {
            sender.state = .on
            NSSound.beep()
        }
    }
    
    @objc private func showPowerToggled(_ sender: NSButton) {
        let wantShow = (sender.state == .on)
        let success = SettingsManager.shared.setShowPower(wantShow)
        if !success {
            sender.state = .on
            NSSound.beep()
        }
    }
    
    @objc private func arrowStyleChanged(_ sender: NSButton) {
        if sender == arrowClassicRadio {
            arrowClassicRadio.state = .on
            arrowTriangleRadio.state = .off
            SettingsManager.shared.setArrowStyle(.standard)
        } else {
            arrowClassicRadio.state = .off
            arrowTriangleRadio.state = .on
            SettingsManager.shared.setArrowStyle(.triangle)
        }
    }
    
    @objc private func launchAtLoginToggled(_ sender: NSButton) {
        appDelegate?.toggleLaunchAtLogin()
        if let appDelegate = appDelegate {
            sender.state = appDelegate.isLaunchAtLoginEnabled() ? .on : .off
        }
    }
    
    @objc private func resetTotalsClicked(_ sender: NSButton) {
        appDelegate?.resetTotals()
    }
    
    public func showSettings() {
        guard let window = window else { return }
        updateValues()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
