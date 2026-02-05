# QuickLaunch

A fast, native app launcher for macOS that recreates the classic Launchpad experience.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

![QuickLaunch Screenshot](screenshots/main.png)

## Features

- **Full-screen Launchpad** - Blurred wallpaper background, just like native macOS
- **App Grid** - Display all installed applications with smooth animations
- **Drag & Drop** - Reorder apps by dragging, create folders by dropping one app onto another
- **Folders** - Organize apps into folders, rename them, dissolve when needed
- **Search** - Real-time filtering with Chinese pinyin support
- **Auto Organize** - One-click automatic organization by app category
- **Global Hotkey** - Press `⌘⇧Space` to launch from anywhere
- **Status Bar** - Quick access from menu bar
- **Auto Update** - Automatically detects newly installed/removed apps
- **Bilingual** - Chinese and English based on system language

## Installation

### Build from Source

```bash
# Clone the repository
git clone https://github.com/vorojar/QuickLaunch.git
cd QuickLaunch

# Build and create app bundle
./scripts/build.sh

# Run
open QuickLaunch.app

# Or install to Applications
cp -r QuickLaunch.app /Applications/
```

### Requirements

- macOS 14.0 (Sonoma) or later
- Xcode Command Line Tools or Xcode

## Usage

| Action | How |
|--------|-----|
| Open Launchpad | `⌘⇧Space` or click status bar icon |
| Close Launchpad | `Esc` or click outside |
| Launch App | Click on app icon |
| Search | Start typing |
| Quick Launch | Type and press `Enter` |
| Create Folder | Drag one app onto another |
| Rename Folder | Click folder to open, then click name |
| Reorder Apps | Drag and drop |
| Delete Mode | Long press on any app |
| Context Menu | Right-click on app |

## Project Structure

```
QuickLaunch/
├── Sources/QuickLaunch/
│   ├── QuickLaunchApp.swift      # App entry point
│   ├── AppDelegate.swift         # Status bar, hotkey, window management
│   ├── AppState.swift            # Central state management
│   ├── Models/
│   │   ├── LaunchItem.swift      # App/Folder/URL model
│   │   └── AppUsageRecord.swift  # Usage tracking model
│   ├── Views/
│   │   ├── MainContentView.swift # Main launchpad UI
│   │   ├── AppIconView.swift     # App icon component
│   │   └── FolderView.swift      # Folder components
│   ├── Services/
│   │   ├── AppScanner.swift      # Scan installed apps
│   │   ├── UsageTracker.swift    # Track app usage
│   │   ├── DataStore.swift       # JSON persistence
│   │   └── DirectoryMonitor.swift# Watch for new apps
│   └── Utilities/
│       ├── IconCache.swift       # Icon caching
│       └── Localization.swift    # i18n support
├── Resources/
│   ├── Info.plist
│   ├── AppIcon.icns
│   └── StatusBarIcon.png
├── scripts/
│   └── build.sh                  # Build script
└── Package.swift
```

## Data Storage

User data is stored in `~/Library/Application Support/QuickLaunch/`:

- `grid_layout.json` - App arrangement and folders
- `usage_stats.json` - App usage statistics
- `hidden_apps.json` - Apps removed from Launchpad

## License

MIT License

## Acknowledgments

Built with Swift, SwiftUI, and AppKit.
