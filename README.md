# MacTrayMonitor

<p align="center">
  <strong>⚡ A lightning-fast, zero-dependency native macOS menu bar monitor displaying real-time upload/download network speeds and hardware battery charging/discharging wattage directly in your tray.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2012.0%2B-black?style=flat-square&logo=apple" alt="Platform: macOS" />
  <img src="https://img.shields.io/badge/language-Swift%206%20%2B%20C-orange?style=flat-square&logo=swift" alt="Language: Swift" />
  <img src="https://img.shields.io/badge/architecture-Apple%20Silicon%20%2F%20Intel-blue?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/CPU%20Usage-%3C%200.1%25-brightgreen?style=flat-square" alt="CPU Usage" />
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License: MIT" />
</p>

---

## ✨ Features

- **Dual-Row Dynamic Tray Icon**:
  - **Network Speed Indicator** (Optional):
    - **Top Row**: Upload speed with up arrow (`0.0 ↑`)
    - **Bottom Row**: Download speed with down arrow (`12.4 ↓`)
  - **Hardware Power & Battery Monitor** (Direct AppleSMC hardware sensors):
    - **When Charging**: Top row shows lightning bolt (`⚡`), bottom row shows real-time charging wattage (e.g. `17.6W`)
    - **When Discharging (on Battery)**: Top row shows battery icon (`🔋` with real-time level fill), bottom row shows active system power consumed (`PSTR` sensor, e.g. `6.0W`, matching hardware tools like powerflow)
    - **When Connected & Full**: Shows AC status and current system wattage
  - **Pixel-Perfect Alignment**: Monospaced tabular digits ensure the menu bar item never jitters or shifts width as speeds/wattage fluctuate.
  - **Retina & Theme Adaptive**: Rendered via macOS vector template drawing (`isTemplate = true`), automatically adapting to Light Mode, Dark Mode, accent colors, and desktop wallpaper tints.

- **Dedicated Settings Window (`⌘,`)**:
  - **Tray Icon Visibility**: Toggle Network Speed and Power indicators independently.
  - **Network Arrow Style**: Choose between `↑ ↓` (Classic Arrows) and `▲ ▼` (Solid Triangles).
  - **Live Power Telemetry**: View real-time battery percentage, power draw, adapter wattage, battery temperature, and cycle count.
  - **General**: Toggle Launch at Login and reset session statistics.

- **Interactive Status Menu**:
  - **Live Summary**: Prominent `download=10mb, upload=5mb` header.
  - **High-Precision Speeds**: Exact download and upload rates in MB/s.
  - **Session Totals**: Cumulative data transferred (in MB / GB) since launch.
  - **Active Network Interface**: Real-time interface detection (e.g., `en0` Wi-Fi, Ethernet).
  - **Battery & Power Details**: Live charging rate, system load, adapter type, temperature, and cycle count.
  - **⚙️ Settings...**: Open the native preferences window with `⌘,`.

- **VPN & Network Switching Resilient**:
  - Direct kernel interface polling using BSD `sysctl` (`NET_RT_IFLIST2`) with 64-bit precision.
  - Filters out virtual tunnels (`utun*`, `ipsec*`), loopback (`lo0`), and Apple Direct Link (`awdl0`, `llw0`).
  - Direct AppleSMC kernel UserClient bridge for true 1-second instantaneous power measurements.

- **Ultra-Lightweight & Native**:
  - Pure Swift & AppKit + lightweight C SMC bridge. **Zero external dependencies**.
  - Background agent (`LSUIElement = true`) — runs silently in your menu bar without cluttering your Dock.
  - CPU usage sits comfortably below **0.1%**.

---

## 🖥️ Menu Bar Layout

### Both Indicators Enabled
```text
┌────────────────────────────────────────────────────────┐
│  0.2 ↑    ⚡                                           │
│ 15.4 ↓  17.6W                                          │
└────────────────────────────────────────────────────────┘
```

### Power Only (Discharging on Battery)
```text
┌────────────────────────────────────────────────────────┐
│   🔋                                                   │
│  6.0W                                                  │
└────────────────────────────────────────────────────────┘
```

### Network Only
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
│ 📥 Total Downloaded: 2.14 GB                           │
│ 📤 Total Uploaded: 142.8 MB                            │
│ 🌐 Active Interface: en0                               │
├────────────────────────────────────────────────────────┤
│ ⚡ Charging: 17.6W (86%)                               │
│ ⚡ System In: 17.6W | System Load: 6.3W                 │
│ 🔌 Power Source: 20W Adapter (Connected)               │
│ 🔋 Level: 86% | 30.4°C | 574 Cycles                    │
├────────────────────────────────────────────────────────┤
│ ⚙️ Settings...                                   ⌘,    │
│ 🔄 Reset Statistics                             ⌘R     │
│ 🚀 Launch at Login                                     │
├────────────────────────────────────────────────────────┤
│ ❌ Quit                                         ⌘Q     │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 Installation & Quick Start

### Option 1: Download Pre-built DMG (Fastest)

1. Download **[`MacTrayMonitor-v2.0.0.dmg`](https://github.com/erdinc11/MacTrayMonitor/releases/latest/download/MacTrayMonitor-v2.0.0.dmg)** from [Releases](https://github.com/erdinc11/MacTrayMonitor/releases).
2. Double-click to open the `.dmg` file.
3. Drag and drop **`MacTrayMonitor.app`** into the **Applications** folder shortcut.
4. Launch **MacTrayMonitor** from your Applications!

### Option 2: Build and Install from Source

```bash
git clone https://github.com/erdinc11/MacTrayMonitor.git
cd MacTrayMonitor
./build.sh --install
```

Or build and run locally without installing:

```bash
./build.sh --run
```

To create a release DMG:

```bash
./build.sh --dmg
```

---

## 🛠️ Project Structure

```text
MacTrayMonitor/
├── Sources/
│   ├── SMCBridge.h                   # C bridge header for AppleSMC UserClient
│   ├── SMCBridge.c                   # C bridge implementation for hardware sensors (PSTR, PDTR, PPBR, TB0T)
│   ├── PowerMonitor.swift            # Hardware AppleSMC & IOKit power telemetry service
│   ├── SettingsManager.swift         # Persistent user defaults & visibility configuration
│   ├── SettingsWindowController.swift# Native AppKit settings & preferences window
│   ├── NetworkMonitor.swift          # 64-bit kernel sysctl network bandwidth engine
│   ├── StatusBarView.swift           # Dual-row vector template renderer (speeds, ⚡, 🔋, wattage)
│   ├── AppDelegate.swift             # Status item lifecycle, menu actions & launch agent
│   └── main.swift                    # App entry point
├── Resources/
│   ├── Info.plist                    # LSUIElement=true configuration
│   ├── AppIcon.icns
│   └── dmg_background.png
├── scripts/
│   └── generate_dmg_background.swift # Styled DMG background generator
├── build.sh                          # Universal binary build, install & DMG script
├── LICENSE                           # MIT License
└── README.md
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
