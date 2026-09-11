# NetSpeedMonitor

<p align="center">
  <strong>⚡ A lightning-fast, zero-dependency native macOS status bar monitor displaying real-time upload and download speeds directly in your menu bar.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2012.0%2B-black?style=flat-square&logo=apple" alt="Platform: macOS" />
  <img src="https://img.shields.io/badge/language-Swift%206-orange?style=flat-square&logo=swift" alt="Language: Swift" />
  <img src="https://img.shields.io/badge/architecture-Apple%20Silicon%20%2F%20Intel-blue?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/CPU%20Usage-%3C%200.1%25-brightgreen?style=flat-square" alt="CPU Usage" />
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License: MIT" />
</p>

---

## ✨ Features

- **Dual-Row Dynamic Tray Icon**:
  - **Top Row**: Upload speed with up arrow (`0.0 ↑`)
  - **Bottom Row**: Download speed with down arrow (`12.4 ↓`)
  - **Clean & Minimalist**: Displays numbers only in MB/s without distracting "mb/s" text suffixes.
  - **Pixel-Perfect Alignment**: Monospaced tabular digits ensure the menu bar item never jitters or shifts width as speeds fluctuate.
  - **Retina & Theme Adaptive**: Rendered via macOS vector template drawing (`isTemplate = true`), automatically adapting to Light Mode, Dark Mode, accent colors, and desktop wallpaper tints.

- **Interactive Status Menu (Right-Click & Left-Click)**:
  - **Live Summary**: Prominent `download=10mb, upload=5mb` header.
  - **High-Precision Speeds**: Exact two-decimal download and upload rates in MB/s.
  - **Session Totals**: Cumulative data transferred (in MB / GB) since launch.
  - **Active Network Interface**: Real-time interface detection (e.g., `en0` Wi-Fi, Ethernet).
  - **Customizable Arrow Style**: Switch anytime between `↑ ↓` (Classic Arrows) and `▲ ▼` (Solid Triangles).
  - **Launch at Login**: Easily enable or disable starting automatically when you log into your Mac.
  - **Session Reset**: One-click counter reset.

- **VPN & Network Switching Resilient**:
  - Direct kernel interface polling using BSD `sysctl` (`NET_RT_IFLIST2`) with 64-bit precision.
  - **No Double-Counting**: Virtual tunnels (`utun*`, `ipsec*`), loopback (`lo0`), and Apple Direct Link (`awdl0`, `llw0`) are filtered out. When a VPN is active (WireGuard, OpenVPN, Tailscale, Cloudflare WARP, etc.), traffic physically passing through the network adapter is captured accurately without duplicate counting.
  - **Zero Spikes**: Handles Wi-Fi/Ethernet reconnections, counter rollovers, and Mac sleep/wake cycles gracefully without artificial spikes.

- **Ultra-Lightweight & Native**:
  - Pure Swift & AppKit. **Zero external dependencies**, no CocoaPods, no SPM packages, and no Electron bloat.
  - Background agent (`LSUIElement = true`) — runs silently in your menu bar without cluttering your Dock.
  - CPU usage sits comfortably below **0.1%**.

---

## 🖥️ Menu Bar Layout

```text
┌────────────────────────────────────────────────────────┐
│  0.2 ↑                                                 │
│ 15.4 ↓                                                 │
└────────────────────────────────────────────────────────┘
```

When clicked or right-clicked:

```text
┌────────────────────────────────────────────────────────┐
│ download=15mb, upload=0mb                              │
├────────────────────────────────────────────────────────┤
│ ⬇️ Download Speed: 15.42 MB/s                           │
│ ⬆️ Upload Speed: 0.21 MB/s                             │
├────────────────────────────────────────────────────────┤
│ 📥 Total Downloaded: 2.14 GB                           │
│ 📤 Total Uploaded: 142.8 MB                            │
├────────────────────────────────────────────────────────┤
│ 🌐 Active Interface: en0                               │
├────────────────────────────────────────────────────────┤
│ Arrow Style (Tray Icon) ▶  ✓ ↑ ↓ Classic Arrows        │
│                              ▲ ▼ Solid Triangles       │
│ 🔄 Reset Statistics                                    │
│ 🚀 Launch at Login                                     │
├────────────────────────────────────────────────────────┤
│ ❌ Quit                                                │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 Installation & Quick Start

### Option 1: Install directly to `/Applications` (Recommended)

Clone the repository and run the build script with `--install`:

```bash
git clone https://github.com/erdinc11/NetSpeedMonitor.git
cd NetSpeedMonitor
./build.sh --install
```

This compiles the native `.app` bundle, places it in `/Applications/NetSpeedMonitor.app`, and launches it immediately.

### Option 2: Build and run locally

```bash
git clone https://github.com/erdinc11/NetSpeedMonitor.git
cd NetSpeedMonitor
./build.sh --run
```

---

## 🛠️ Project Structure

```text
NetSpeedMonitor/
├── Sources/
│   ├── NetworkMonitor.swift    # 64-bit kernel sysctl network bandwidth engine
│   ├── StatusBarView.swift     # HiDPI dual-line template image generator
│   ├── AppDelegate.swift       # Status item lifecycle, menu actions & launch agent
│   └── main.swift              # App entry point
├── Resources/
│   └── Info.plist              # LSUIElement=true configuration
├── build.sh                    # One-command build & install script
├── LICENSE                     # MIT License
└── README.md
```

---

## ⚙️ How It Works

1. **Kernel Polling**: Every 1.0 second, `NetworkMonitor` queries the Darwin kernel via `sysctl` with `NET_RT_IFLIST2` to fetch the 64-bit `ifi_ibytes` and `ifi_obytes` counters.
2. **Interface Filtering**: Internal virtual links (`lo0`, `awdl0`, `llw0`, `utun*`, `ipsec*`, `bridge*`, `anpi*`) are excluded. Only physical running interfaces (`en*`, `pdp_ip*`) are tracked.
3. **Template Rendering**: `StatusBarIconRenderer` formats the upload and download values into an `NSImage` drawn with `isTemplate = true`. macOS automatically handles Light Mode, Dark Mode, and menu bar tinting with subpixel anti-aliasing on Retina displays.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
