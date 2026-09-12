import Foundation
import IOKit

public struct PowerStats {
    public var isCharging: Bool = false
    public var isPluggedIn: Bool = false
    public var isFullyCharged: Bool = false
    public var batteryLevel: Int = 100
    public var activeWatts: Double = 0.0
    public var systemInWatts: Double = 0.0
    public var systemLoadWatts: Double = 0.0
    public var batteryWatts: Double = 0.0
    public var adapterWatts: Int = 0
    public var adapterName: String = ""
    public var temperature: Double = 0.0
    public var cycleCount: Int = 0
    public var hasBattery: Bool = true
    
    public init() {}
}

public class PowerMonitor {
    
    public init() {
        _ = smc_open()
    }
    
    deinit {
        smc_close()
    }
    
    public func sample() -> PowerStats {
        var stats = PowerStats()
        
        // 1. Read directly from SMC (matching powerflow's hardware sensors)
        let smc = smc_read_all()
        
        // 2. Read supplementary battery info from AppleSmartBattery (for adapter, cycles, percent)
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        var iokitDict: [String: Any]? = nil
        if entry != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                iokitDict = dict
            }
            IOObjectRelease(entry)
        }
        
        if let dict = iokitDict {
            stats.hasBattery = true
            let iokitIsCharging = dict["IsCharging"] as? Bool ?? ((dict["IsCharging"] as? Int ?? 0) != 0)
            stats.isPluggedIn = dict["ExternalConnected"] as? Bool ?? ((dict["ExternalConnected"] as? Int ?? 0) != 0)
            stats.isFullyCharged = dict["FullyCharged"] as? Bool ?? ((dict["FullyCharged"] as? Int ?? 0) != 0)
            
            let currentCapacity = dict["CurrentCapacity"] as? Int ?? 0
            let maxCapacity = max(dict["MaxCapacity"] as? Int ?? 100, 1)
            stats.batteryLevel = max(0, min(100, (currentCapacity * 100) / maxCapacity))
            
            if let adapter = dict["AdapterDetails"] as? [String: Any] {
                stats.adapterWatts = adapter["Watts"] as? Int ?? 0
                stats.adapterName = adapter["Name"] as? String ?? (adapter["Description"] as? String ?? "")
            }
            stats.cycleCount = dict["CycleCount"] as? Int ?? 0
            
            let tempRaw = dict["Temperature"] as? Double ?? (dict["Temperature"] as? Int).map(Double.init) ?? 0.0
            stats.temperature = tempRaw > 1000.0 ? (tempRaw / 100.0) : tempRaw
            
            stats.isCharging = iokitIsCharging
        } else if smc.is_valid {
            stats.hasBattery = true
            if smc.full_capacity > 0 {
                stats.batteryLevel = max(0, min(100, Int((smc.current_capacity / smc.full_capacity) * 100.0)))
            }
            stats.isPluggedIn = smc.delivery_rate > 0.5
        } else {
            stats.hasBattery = false
            return stats
        }
        
        // 3. Process SMC hardware telemetry (Primary, identical to powerflow)
        if smc.is_valid {
            stats.systemLoadWatts = Double(max(0.0, smc.system_total))
            stats.batteryWatts = Double(max(0.0, smc.battery_rate))
            stats.systemInWatts = Double(max(0.0, smc.delivery_rate))
            
            if smc.temperature > 0.0 {
                stats.temperature = Double(smc.temperature)
            }
            
            if smc.charging_status > 0.0 || smc.delivery_rate > 1.0 {
                stats.isCharging = true
                stats.isPluggedIn = true
            } else if !stats.isPluggedIn {
                stats.isCharging = false
            }
            
            // In powerflow:
            // if smc.is_charging() { smc.delivery_rate } else { smc.system_total }
            if stats.isCharging {
                stats.activeWatts = stats.systemInWatts > 0.1 ? stats.systemInWatts : stats.systemLoadWatts
            } else {
                // On battery or running on AC idle: system_total (PSTR) is the real-time system power!
                stats.activeWatts = stats.systemLoadWatts
            }
        } else if let dict = iokitDict {
            // Fallback for systems where SMC keys are unavailable
            if let telemetry = dict["PowerTelemetryData"] as? [String: Any] {
                if let v = telemetry["SystemPowerIn"] as? Double ?? (telemetry["SystemPowerIn"] as? Int).map(Double.init) {
                    stats.systemInWatts = max(0.0, v / 1000.0)
                }
                if let v = telemetry["SystemLoad"] as? Double ?? (telemetry["SystemLoad"] as? Int).map(Double.init) {
                    stats.systemLoadWatts = max(0.0, v / 1000.0)
                }
                if let v = telemetry["BatteryPower"] as? Double ?? (telemetry["BatteryPower"] as? Int).map(Double.init) {
                    stats.batteryWatts = max(0.0, v / 1000.0)
                }
            }
            if stats.isCharging {
                stats.activeWatts = stats.systemInWatts > 0.1 ? stats.systemInWatts : stats.batteryWatts
            } else {
                stats.activeWatts = stats.systemLoadWatts > 0.1 ? stats.systemLoadWatts : stats.batteryWatts
            }
        }
        
        return stats
    }
}
