# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuickLaunch is a native macOS app launcher (Launchpad replacement) built with Swift 5.9 and SwiftUI. It runs as a menu bar app with a full-screen overlay window, global hotkey (`Cmd+Shift+Space`), drag-and-drop reordering, folder management, and real-time search with Chinese pinyin support.

- **Platform:** macOS 14.0+ (Sonoma)
- **UI Framework:** SwiftUI hosted in AppKit (`NSHostingView` in a borderless `NSWindow`)
- **Package Manager:** Swift Package Manager (no external dependencies)
- **Language:** Swift, with bilingual UI (English/Chinese via `Localization.swift`)

## Build & Run

```bash
# Build release binary
swift build -c release

# Build .app bundle (compiles + creates QuickLaunch.app with resources)
./scripts/build.sh

# Run the app
open QuickLaunch.app
```

There are no tests or linting configured in this project.

## Architecture

**App lifecycle** uses raw AppKit (not SwiftUI App protocol). `QuickLaunchApp.swift` defines `@main AppMain` which creates `NSApplication` and sets `AppDelegate` manually. This is intentional — the app needs low-level control over window behavior, global hotkeys (Carbon API), and menu bar status item.

**State management** is centralized in `AppState` (singleton via `AppState.shared`), an `ObservableObject` that owns all app data and services:
- `gridItems: [LaunchItem]` — the entire grid layout (apps + folders)
- Services: `AppScanner`, `UsageTracker`, `DataStore`, `DirectoryMonitor`, `IconCache`
- Handles search, drag reorder, folder CRUD, auto-organize, wallpaper capture

**Window system:** `LaunchpadWindow` manages a borderless, transparent `KeyableWindow` that covers the full screen. Show/hide uses alpha animation. The window sits just below `mainMenu` level.

**Data persistence** is JSON-based via `DataStore`, stored in `~/Library/Application Support/QuickLaunch/`:
- `grid_layout.json` — app arrangement and folders
- `usage_stats.json` — launch counts
- `hidden_apps.json` — apps removed from view

**App detection:** `AppScanner` scans `/Applications`, `/System/Applications`, and `~/Applications`. `DirectoryMonitor` uses `DispatchSource` to watch these directories, plus a 30-second polling fallback (SIP can block FS events). New apps are merged into the existing layout without disrupting user arrangement.

**Global hotkey** is registered via Carbon `RegisterEventHotKey` API in `AppDelegate`.

## Key Patterns

- `LaunchItem` is the universal model — `.app`, `.folder`, and `.url` kinds. Folders use a `children` array of `LaunchItem`.
- Localization uses a custom `L10n` enum (not `.strings` files) in `Localization.swift` that switches on system locale.
- Icon loading is async with `IconCache` pre-warming all icons on launch.
- The landing page (`index.html`) is a standalone static site for GitHub Pages, unrelated to the Swift app.
