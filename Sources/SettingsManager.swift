import Foundation

public class SettingsManager {
    public static let shared = SettingsManager()
    
    public static let didChangeNotification = Notification.Name("MacTrayMonitorSettingsDidChange")
    
    private enum Keys {
        static let showNetworkSpeed = "ShowNetworkSpeed"
        static let showPower = "ShowPower"
        static let arrowStyle = "ArrowStyle"
    }
    
    private let defaults = UserDefaults.standard
    
    public private(set) var showNetworkSpeed: Bool {
        get {
            if defaults.object(forKey: Keys.showNetworkSpeed) == nil {
                return true // default enabled
            }
            return defaults.bool(forKey: Keys.showNetworkSpeed)
        }
        set {
            defaults.set(newValue, forKey: Keys.showNetworkSpeed)
        }
    }
    
    public private(set) var showPower: Bool {
        get {
            if defaults.object(forKey: Keys.showPower) == nil {
                return true // default enabled
            }
            return defaults.bool(forKey: Keys.showPower)
        }
        set {
            defaults.set(newValue, forKey: Keys.showPower)
        }
    }
    
    public private(set) var arrowStyle: ArrowStyle {
        get {
            if let saved = defaults.string(forKey: Keys.arrowStyle),
               let style = ArrowStyle(rawValue: saved) {
                return style
            }
            return .standard
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.arrowStyle)
        }
    }
    
    private init() {}
    
    @discardableResult
    public func setShowNetworkSpeed(_ show: Bool) -> Bool {
        // Prevent hiding both indicators
        if !show && !showPower {
            return false
        }
        showNetworkSpeed = show
        NotificationCenter.default.post(name: SettingsManager.didChangeNotification, object: self)
        return true
    }
    
    @discardableResult
    public func setShowPower(_ show: Bool) -> Bool {
        // Prevent hiding both indicators
        if !show && !showNetworkSpeed {
            return false
        }
        showPower = show
        NotificationCenter.default.post(name: SettingsManager.didChangeNotification, object: self)
        return true
    }
    
    public func setArrowStyle(_ style: ArrowStyle) {
        arrowStyle = style
        NotificationCenter.default.post(name: SettingsManager.didChangeNotification, object: self)
    }
}
