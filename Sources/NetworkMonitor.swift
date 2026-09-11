import Foundation
import Darwin

public struct BandwidthStats {
    public var uploadSpeedMB: Double = 0.0      // Current upload speed in MB/s
    public var downloadSpeedMB: Double = 0.0    // Current download speed in MB/s
    public var totalUploadBytes: UInt64 = 0     // Cumulative bytes uploaded since start
    public var totalDownloadBytes: UInt64 = 0   // Cumulative bytes downloaded since start
    public var activeInterfaces: [String] = []  // Names of monitored active interfaces (e.g. en0)
    public var primaryInterface: String = ""    // Primary active interface name
}

public class NetworkMonitor {
    private var lastSampleTime: Date = Date()
    private var lastInterfaceBytes: [String: (ibytes: UInt64, obytes: UInt64)] = [:]
    private var isFirstSample: Bool = true
    
    // Running session totals
    private var cumulativeInBytes: UInt64 = 0
    private var cumulativeOutBytes: UInt64 = 0
    
    public init() {
        _ = sample()
    }
    
    /// Queries the kernel for network interface byte counts using sysctl NET_RT_IFLIST2
    private func queryKernelInterfaces() -> [String: (ibytes: UInt64, obytes: UInt64)] {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len: Int = 0
        var results: [String: (ibytes: UInt64, obytes: UInt64)] = [:]
        
        guard sysctl(&mib, UInt32(mib.count), nil, &len, nil, 0) == 0, len > 0 else {
            return results
        }
        
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: MemoryLayout<Int>.alignment)
        defer { buffer.deallocate() }
        
        guard sysctl(&mib, UInt32(mib.count), buffer, &len, nil, 0) == 0 else {
            return results
        }
        
        var cursor = buffer
        let end = buffer.advanced(by: len)
        
        while cursor < end {
            let msg = cursor.assumingMemoryBound(to: if_msghdr2.self)
            if msg.pointee.ifm_type == RTM_IFINFO2 {
                let data = msg.pointee.ifm_data
                let flags = msg.pointee.ifm_flags
                
                // Extract interface name from sockaddr_dl
                let sdlPtr = cursor.advanced(by: MemoryLayout<if_msghdr2>.size).assumingMemoryBound(to: sockaddr_dl.self)
                let sdl = sdlPtr.pointee
                let nameLen = Int(sdl.sdl_nlen)
                var name = ""
                withUnsafePointer(to: sdl.sdl_data) { ptr in
                    let rawPtr = UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
                    name = String(decoding: UnsafeBufferPointer(start: rawPtr, count: nameLen), as: UTF8.self)
                }
                
                let isLoopback = (flags & Int32(IFF_LOOPBACK)) != 0
                let isUp = (flags & Int32(IFF_UP)) != 0
                let isRunning = (flags & Int32(IFF_RUNNING)) != 0
                
                // Exclude loopback, virtual tunnels, Apple peer-to-peer, internal buses
                // This guarantees that all physical internet traffic is measured accurately
                // and VPN traffic passing through the physical interface is NOT double-counted.
                let isExcluded = name.isEmpty ||
                                 name.hasPrefix("lo") ||      // Loopback
                                 name.hasPrefix("gif") ||     // Generic tunnel
                                 name.hasPrefix("stf") ||     // 6to4 tunnel
                                 name.hasPrefix("awdl") ||    // Apple Wireless Direct Link (AirDrop)
                                 name.hasPrefix("llw") ||     // Low Latency WLAN
                                 name.hasPrefix("bridge") ||  // Virtual bridge
                                 name.hasPrefix("utun") ||    // VPN tunnel (traffic physically passes through en*)
                                 name.hasPrefix("ipsec") ||   // IPSec tunnel
                                 name.hasPrefix("anpi") ||    // Apple internal interconnect
                                 name.hasPrefix("XHC")        // USB virtual controller
                
                if isUp && isRunning && !isLoopback && !isExcluded {
                    results[name] = (data.ifi_ibytes, data.ifi_obytes)
                }
            }
            cursor = cursor.advanced(by: Int(msg.pointee.ifm_msglen))
        }
        
        return results
    }
    
    /// Reads the current bandwidth statistics
    public func sample() -> BandwidthStats {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastSampleTime)
        let currentInterfaces = queryKernelInterfaces()
        
        // If Mac was asleep or sample delay is large (>3s), reset baseline to prevent spikes
        let resetBaseline = isFirstSample || timeDelta > 3.0 || timeDelta < 0.05
        
        var totalInDelta: UInt64 = 0
        var totalOutDelta: UInt64 = 0
        
        if !resetBaseline {
            for (name, counts) in currentInterfaces {
                if let prev = lastInterfaceBytes[name] {
                    // Check for interface counter resets, rollovers, or reconnections
                    if counts.ibytes >= prev.ibytes {
                        totalInDelta += (counts.ibytes - prev.ibytes)
                    }
                    if counts.obytes >= prev.obytes {
                        totalOutDelta += (counts.obytes - prev.obytes)
                    }
                }
            }
        }
        
        isFirstSample = false
        lastSampleTime = now
        lastInterfaceBytes = currentInterfaces
        
        // Accumulate session totals
        cumulativeInBytes += totalInDelta
        cumulativeOutBytes += totalOutDelta
        
        let elapsed = max(timeDelta, 0.1)
        let inMBs = (Double(totalInDelta) / (1024.0 * 1024.0)) / elapsed
        let outMBs = (Double(totalOutDelta) / (1024.0 * 1024.0)) / elapsed
        
        var stats = BandwidthStats()
        stats.uploadSpeedMB = outMBs
        stats.downloadSpeedMB = inMBs
        stats.totalUploadBytes = cumulativeOutBytes
        stats.totalDownloadBytes = cumulativeInBytes
        stats.activeInterfaces = Array(currentInterfaces.keys).sorted()
        stats.primaryInterface = currentInterfaces.keys.contains("en0") ? "en0" : (currentInterfaces.keys.first ?? "")
        
        return stats
    }
    
    public func resetTotals() {
        cumulativeInBytes = 0
        cumulativeOutBytes = 0
    }
}
