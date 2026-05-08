# Changelog

## [Unreleased]

## [1.0.4] - 2026-05-08

### Fixed
- Hide QuickLaunch when another app becomes active, matching the expected Launchpad-style behavior.
- Clean up stale QuickLaunch Installer DMG mounts before packaging so repeat builds do not fail on read-only volumes.

## [1.0.3] - 2026-05-08

### Fixed
- Hide QuickLaunch immediately when launching an app so slow target app startup does not make the launcher feel stuck.
- Use system-localized app display names, including saved layouts, so searches like "活动监视器" work.
- Include additional Apple system utility apps from CoreServices.
- Fix zh-Hans string parsing for the remove confirmation message.

### Improved
- Focus the search field automatically when QuickLaunch opens.
- Search now matches localized names, bundle identifiers, and original `.app` filenames with normalized matching.

### Fixed
- Window level too high (mainMenu-1), blocking system authorization dialogs when launching new apps — lowered to below modalPanel
- "Remove from LaunchPad" and "Move to Trash" not working for apps inside folders (only searched top-level grid)
- Jiggle mode delete on folders silently losing all child apps (now dissolves folder, children return to grid)
- Data race: `mergeApps` read `@Published` properties from background threads — split into background scan + main thread merge
- Menu bar "Rescan" destroying user folder layout — now uses merge-based rescan preserving arrangement
- `loadData` calling `loadGridLayout()` twice on startup
- Concurrent scan race condition — replaced non-atomic flag with serial DispatchQueue
- AppleScript injection vulnerability in "Get Info" context menu — replaced with NSWorkspace API
- `IconCache.prerenderIcon` using `lockFocus` from background threads (main-thread-only API) — replaced with thread-safe NSBitmapImageRep
- `CIFilter.outputImage` force-unwrap crash risk in wallpaper blur pipeline
- `confirmTrash` silently removing app from grid when `trashItem` fails (e.g. SIP-protected apps)
- Folder auto-entering rename mode on every open, causing accidental name changes
- Search cache returning stale results after grid items change

### Improved
- Auto-organize category folder names now respect system language (Chinese/English)
- Folder names auto-migrate to match current locale on startup after language switch
