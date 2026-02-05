import SwiftUI
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var gridItems: [LaunchItem] = []
    @Published var searchText: String = ""
    @Published var expandedFolderID: UUID? = nil
    @Published var expandedFolderOrigin: CGPoint = .zero
    @Published var dragTargetID: UUID? = nil
    @Published var isVisible: Bool = false
    @Published var isJiggling: Bool = false
    @Published var draggingItemID: UUID? = nil
    @Published var wallpaperImage: NSImage?

    // Delete confirmation
    @Published var pendingDeleteItem: LaunchItem? = nil
    @Published var showDeleteConfirm: Bool = false

    // Hidden apps (removed from LaunchPad but still installed)
    var hiddenBundleIDs: Set<String> = []

    let dataStore = DataStore()
    let appScanner = AppScanner()
    let usageTracker = UsageTracker()
    let iconCache = IconCache()

    private var cancellables = Set<AnyCancellable>()
    private var lastMoveTarget: UUID? // debounce reorder
    private var directoryMonitor: DirectoryMonitor?
    private var rescanTimer: Timer?

    // Search cache
    private var cachedSearchText: String = ""
    private var cachedSearchResult: [LaunchItem] = []

    private init() {
        loadData()
        setupUsageTracking()
        captureWallpaper()
        startDirectoryMonitoring()
        startPeriodicRescan()
        preloadAllIcons()
        setupVisibilityRescan()
    }

    func loadData() {
        if let saved = dataStore.loadGridLayout(), !saved.isEmpty {
            gridItems = saved
        } else {
            gridItems = appScanner.scanApplications()
        }
        usageTracker.records = dataStore.loadUsageStats()
        hiddenBundleIDs = dataStore.loadHiddenApps()
        if dataStore.loadGridLayout() == nil { sortByUsage() }
    }

    func save() {
        dataStore.saveGridLayout(gridItems)
        dataStore.saveUsageStats(usageTracker.records)
        dataStore.saveHiddenApps(hiddenBundleIDs)
    }

    func sortByUsage() {
        gridItems.sort { a, b in
            let ac = usageTracker.launchCount(for: a.bundleIdentifier ?? "")
            let bc = usageTracker.launchCount(for: b.bundleIdentifier ?? "")
            if ac != bc { return ac > bc }
            return a.name < b.name
        }
    }

    private func setupUsageTracking() {
        usageTracker.onAppLaunched = { [weak self] _ in self?.save() }
        usageTracker.startTracking()
    }

    // MARK: - Preload Icons

    private func preloadAllIcons() {
        let items = gridItems
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.iconCache.preload(items)
        }
    }

    // MARK: - Directory Monitoring (auto-detect new/removed apps)

    private func startDirectoryMonitoring() {
        let paths = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]
        directoryMonitor = DirectoryMonitor(paths: paths) { [weak self] in
            self?.mergeApps()
        }
    }

    /// Rescan every 30 seconds as fallback (DispatchSource may miss events due to SIP).
    private func startPeriodicRescan() {
        rescanTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .utility).async {
                self?.mergeApps()
            }
        }
    }

    /// Rescan when the panel becomes visible.
    private func setupVisibilityRescan() {
        $isVisible
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                DispatchQueue.global(qos: .userInitiated).async {
                    self?.mergeApps()
                }
            }
            .store(in: &cancellables)
    }

    /// Merge newly installed apps and remove uninstalled ones, preserving user layout.
    private func mergeApps() {
        let scanned = appScanner.scanApplications()

        // Collect all existing bundle IDs (top-level + inside folders)
        var existingBIDs = Set<String>()
        for item in gridItems {
            if let bid = item.bundleIdentifier { existingBIDs.insert(bid) }
            if let children = item.children {
                for child in children {
                    if let bid = child.bundleIdentifier { existingBIDs.insert(bid) }
                }
            }
        }

        // Collect all scanned bundle IDs
        let scannedBIDs = Set(scanned.compactMap(\.bundleIdentifier))

        // Find new apps (in scanned but not in existing, and not hidden)
        let newApps = scanned.filter { item in
            guard let bid = item.bundleIdentifier else { return false }
            return !existingBIDs.contains(bid) && !hiddenBundleIDs.contains(bid)
        }

        // Find removed apps (in existing but not in scanned)
        let removedBIDs = existingBIDs.subtracting(scannedBIDs)

        guard !newApps.isEmpty || !removedBIDs.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // Remove uninstalled apps
            if !removedBIDs.isEmpty {
                withAnimation(.spring(duration: 0.25)) {
                    // Remove from top-level (non-folder items)
                    self.gridItems.removeAll { item in
                        guard item.kind != .folder else { return false }
                        if let bid = item.bundleIdentifier { return removedBIDs.contains(bid) }
                        return false
                    }
                    // Remove from inside folders
                    for i in self.gridItems.indices where self.gridItems[i].kind == .folder {
                        self.gridItems[i].children?.removeAll { child in
                            if let bid = child.bundleIdentifier { return removedBIDs.contains(bid) }
                            return false
                        }
                    }
                    // Dissolve empty/single-child folders in a separate reverse pass
                    for i in stride(from: self.gridItems.count - 1, through: 0, by: -1) {
                        guard self.gridItems[i].kind == .folder else { continue }
                        if let ch = self.gridItems[i].children, ch.count <= 1 {
                            let remaining = ch
                            self.gridItems.remove(at: i)
                            for (j, c) in remaining.enumerated() {
                                self.gridItems.insert(c, at: min(i + j, self.gridItems.count))
                            }
                        }
                    }
                }
            }

            // Append new apps at end
            if !newApps.isEmpty {
                withAnimation(.spring(duration: 0.25)) {
                    self.gridItems.append(contentsOf: newApps)
                }
                // Preload icons for new apps
                DispatchQueue.global(qos: .userInitiated).async {
                    self.iconCache.preload(newApps)
                }
            }

            self.save()
        }
    }

    // MARK: - Wallpaper (capture + heavy blur + slight zoom like native)

    func captureWallpaper() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let screen = NSScreen.main,
                  let url = NSWorkspace.shared.desktopImageURL(for: screen),
                  let image = NSImage(contentsOf: url),
                  let tiff = image.tiffRepresentation,
                  let ci = CIImage(data: tiff) else { return }

            // Scale up 5% like native Launchpad
            let scaled = ci.transformed(by: CGAffineTransform(scaleX: 1.05, y: 1.05)
                .translatedBy(x: -ci.extent.width * 0.025, y: -ci.extent.height * 0.025))

            let blur = CIFilter(name: "CIGaussianBlur")!
            blur.setValue(scaled, forKey: kCIInputImageKey)
            blur.setValue(50.0, forKey: kCIInputRadiusKey)

            // Darken
            let darken = CIFilter(name: "CIColorControls")!
            darken.setValue(blur.outputImage!, forKey: kCIInputImageKey)
            darken.setValue(-0.15, forKey: kCIInputBrightnessKey)
            darken.setValue(1.1, forKey: kCIInputSaturationKey)

            guard let output = darken.outputImage else { return }
            let ctx = CIContext(options: [.useSoftwareRenderer: false])
            guard let cg = ctx.createCGImage(output, from: ci.extent) else { return }
            let result = NSImage(cgImage: cg, size: NSSize(width: ci.extent.width, height: ci.extent.height))

            DispatchQueue.main.async { self?.wallpaperImage = result }
        }
    }

    // MARK: - Search (cached)

    var filteredGridItems: [LaunchItem] {
        guard !searchText.isEmpty else { return gridItems }
        let q = searchText.lowercased()
        if q == cachedSearchText { return cachedSearchResult }
        let result = gridItems.filter { $0.matchesSearch(q) }
        cachedSearchText = q
        cachedSearchResult = result
        return result
    }

    // MARK: - Launch

    func launchItem(_ item: LaunchItem) {
        guard let path = item.path else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
        if let bid = item.bundleIdentifier { usageTracker.recordLaunch(bundleIdentifier: bid) }
        save()
        isVisible = false
    }

    // MARK: - Jiggle Mode

    func enterJiggleMode() {
        withAnimation(.easeInOut(duration: 0.15)) { isJiggling = true }
    }

    func exitJiggleMode() {
        withAnimation(.easeInOut(duration: 0.15)) { isJiggling = false }
        lastMoveTarget = nil
    }

    // MARK: - Delete / Trash (with confirmation for trash only)

    @Published var pendingTrashItem: LaunchItem? = nil
    @Published var showTrashConfirm: Bool = false

    /// Remove from LaunchPad only (hide, no confirmation needed)
    func hideFromLaunchpad(_ item: LaunchItem) {
        if let bid = item.bundleIdentifier {
            hiddenBundleIDs.insert(bid)
        }
        withAnimation(.spring(duration: 0.25)) {
            gridItems.removeAll { $0.id == item.id }
        }
        save()
    }

    /// Request to move app to trash (needs confirmation)
    func requestTrash(_ item: LaunchItem) {
        pendingTrashItem = item
        showTrashConfirm = true
    }

    func confirmTrash() {
        guard let item = pendingTrashItem, let path = item.path else { return }
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        withAnimation(.spring(duration: 0.25)) {
            gridItems.removeAll { $0.id == item.id }
        }
        pendingTrashItem = nil
        showTrashConfirm = false
        save()
    }

    func cancelTrash() {
        pendingTrashItem = nil
        showTrashConfirm = false
    }

    // Legacy methods for jiggle mode delete button (now just hides)
    func requestDelete(_ item: LaunchItem) {
        pendingDeleteItem = item
        showDeleteConfirm = true
    }

    func confirmDelete() {
        guard let item = pendingDeleteItem else { return }
        hideFromLaunchpad(item)
        pendingDeleteItem = nil
        showDeleteConfirm = false
    }

    func cancelDelete() {
        pendingDeleteItem = nil
        showDeleteConfirm = false
    }

    // MARK: - Drag Reorder (debounced)

    func moveItem(fromID: UUID, toID: UUID) {
        guard fromID != toID, lastMoveTarget != toID,
              let fi = gridItems.firstIndex(where: { $0.id == fromID }),
              let ti = gridItems.firstIndex(where: { $0.id == toID }) else { return }
        lastMoveTarget = toID
        withAnimation(.spring(duration: 0.2, bounce: 0.05)) {
            let item = gridItems.remove(at: fi)
            gridItems.insert(item, at: ti)
        }
    }

    func endDrag() {
        draggingItemID = nil
        lastMoveTarget = nil
        save()
    }

    // MARK: - Folder Operations

    func createFolder(from a: LaunchItem, and b: LaunchItem) {
        guard let ai = gridItems.firstIndex(where: { $0.id == a.id }),
              let bi = gridItems.firstIndex(where: { $0.id == b.id }) else { return }
        let folder = LaunchItem(name: L10n.newFolder, kind: .folder, children: [a, b])
        let mi = min(ai, bi)
        withAnimation(.spring(duration: 0.25)) {
            gridItems.removeAll { $0.id == a.id || $0.id == b.id }
            gridItems.insert(folder, at: min(mi, gridItems.count))
        }
        save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.expandedFolderID = folder.id
        }
    }

    func addToFolder(item: LaunchItem, folderID: UUID) {
        withAnimation(.spring(duration: 0.25)) {
            gridItems.removeAll { $0.id == item.id }
            // Re-find folder index AFTER removal since indices may have shifted
            guard let fi = gridItems.firstIndex(where: { $0.id == folderID }),
                  gridItems[fi].kind == .folder else { return }
            gridItems[fi].children?.append(item)
        }
        save()
    }

    func removeFromFolder(item: LaunchItem, folderID: UUID) {
        guard let fi = gridItems.firstIndex(where: { $0.id == folderID }) else { return }
        gridItems[fi].children?.removeAll { $0.id == item.id }

        if let ch = gridItems[fi].children, ch.count <= 1 {
            // Dissolve folder: put remaining children + removed item back into grid
            let remaining = ch
            gridItems.remove(at: fi)
            var insertAt = fi
            for c in remaining {
                gridItems.insert(c, at: min(insertAt, gridItems.count))
                insertAt += 1
            }
            gridItems.insert(item, at: min(insertAt, gridItems.count))
        } else {
            // Folder still has 2+ children, just put item after folder
            gridItems.insert(item, at: min(fi + 1, gridItems.count))
        }
        save()
    }

    func renameFolder(id: UUID, newName: String) {
        guard let i = gridItems.firstIndex(where: { $0.id == id }) else { return }
        gridItems[i].name = newName
        save()
    }

    func dissolveFolder(id: UUID) {
        guard let fi = gridItems.firstIndex(where: { $0.id == id }),
              gridItems[fi].kind == .folder else { return }
        let children = gridItems[fi].children ?? []
        withAnimation(.spring(duration: 0.25)) {
            gridItems.remove(at: fi)
            for (i, child) in children.enumerated() {
                gridItems.insert(child, at: min(fi + i, gridItems.count))
            }
        }
        save()
    }

    // MARK: - Auto Organize

    /// Automatically organize apps into folders by category.
    func autoOrganize() {
        // Collect all loose apps (not in folders)
        var looseApps: [LaunchItem] = []
        var folders: [LaunchItem] = []

        for item in gridItems {
            if item.kind == .folder {
                folders.append(item)
            } else if item.kind == .app {
                looseApps.append(item)
            }
        }

        // Group loose apps by category
        var categoryGroups: [String: [LaunchItem]] = [:]
        var uncategorized: [LaunchItem] = []

        for app in looseApps {
            if let folderName = AppScanner.folderName(for: app.category) {
                categoryGroups[folderName, default: []].append(app)
            } else {
                uncategorized.append(app)
            }
        }

        // Build new grid: existing folders first, then new category folders, then uncategorized apps
        var newGrid: [LaunchItem] = []

        // Keep existing folders (they may have user's custom organization)
        newGrid.append(contentsOf: folders)

        // Create new folders for categories with 2+ apps
        for (folderName, apps) in categoryGroups.sorted(by: { $0.key < $1.key }) {
            if apps.count >= 2 {
                // Check if a folder with this name already exists
                if let existingIdx = newGrid.firstIndex(where: { $0.kind == .folder && $0.name == folderName }) {
                    // Add to existing folder
                    newGrid[existingIdx].children?.append(contentsOf: apps)
                } else {
                    // Create new folder
                    let folder = LaunchItem(
                        name: folderName,
                        kind: .folder,
                        children: apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    )
                    newGrid.append(folder)
                }
            } else {
                // Only 1 app in category, don't create folder
                uncategorized.append(contentsOf: apps)
            }
        }

        // Sort folders by name
        newGrid.sort { a, b in
            // Folders first, then apps
            if a.kind == .folder && b.kind != .folder { return true }
            if a.kind != .folder && b.kind == .folder { return false }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }

        // Add uncategorized apps at end, sorted by name
        uncategorized.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        newGrid.append(contentsOf: uncategorized)

        withAnimation(.spring(duration: 0.35)) {
            gridItems = newGrid
        }
        save()
    }
}
