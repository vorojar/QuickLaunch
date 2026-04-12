# QuickLaunch

A fast, native app launcher for macOS that recreates the classic Launchpad experience.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![GitHub release](https://img.shields.io/github/v/release/vorojar/QuickLaunch)](https://github.com/vorojar/QuickLaunch/releases)

![QuickLaunch Screenshot](screenshots/main.png)

## Features

- **Full-screen Launchpad** - Blurred wallpaper background, just like native macOS
- **App Grid** - Display all installed applications with smooth animations
- **Drag & Drop** - Reorder apps by dragging, create folders by dropping one app onto another
- **Folders** - Organize apps into folders, rename them, dissolve when needed
- **Search** - Real-time filtering with Chinese pinyin support
- **Auto Organize** - One-click automatic organization by app category
- **Global Hotkey** - Press `Cmd+Shift+Space` to launch from anywhere
- **Status Bar** - Quick access from menu bar
- **Auto Update** - Automatically detects newly installed/removed apps
- **Bilingual** - Chinese and English based on system language
- **Context Menu** - Right-click for Show in Finder, Get Info, Move to Trash

## Installation

### Method 1: Homebrew (Recommended)

```bash
brew install --cask quicklaunch
```

### Method 2: Direct Download

1. Download the latest [QuickLaunch.dmg](https://github.com/vorojar/QuickLaunch/releases/latest)
2. Open the DMG and drag `QuickLaunch.app` to Applications folder
3. Double-click to launch

## Usage

| Action | How |
|--------|-----|
| Open Launchpad | `Cmd+Shift+Space` or click status bar icon |
| Close Launchpad | `Esc` or click outside |
| Launch App | Click on app icon |
| Search | Start typing |
| Quick Launch | Type and press `Enter` |
| Create Folder | Drag one app onto another |
| Rename Folder | Click folder to open, then click name |
| Reorder Apps | Drag and drop |
| Delete Mode | Long press on any app |
| Context Menu | Right-click on app |

## Performance

| Metric | Value |
|--------|-------|
| App Size | 1.3 MB |
| DMG Size | 454 KB |
| Memory | ~36 MB |
| Idle CPU | 0.0% |
| Dependencies | None |

Pure Swift, zero external dependencies. Icons are pre-rendered at launch for instant display with no frame drops.

## System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac

## Build from Source

```bash
# Clone the repository
git clone https://github.com/vorojar/QuickLaunch.git
cd QuickLaunch

# Build and create app bundle + DMG
./scripts/build.sh

# Run
open QuickLaunch.app
```

## Data Storage

User data is stored in `~/Library/Application Support/QuickLaunch/`:

- `grid_layout.json` - App arrangement and folders
- `usage_stats.json` - App usage statistics
- `hidden_apps.json` - Apps removed from Launchpad

## License

MIT License

## Links

- [Website](https://vorojar.github.io/QuickLaunch)
- [Releases](https://github.com/vorojar/QuickLaunch/releases)
- [Homebrew Cask](https://github.com/Homebrew/homebrew-cask/pull/247853)
