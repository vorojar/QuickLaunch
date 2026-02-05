import SwiftUI

struct LaunchpadRootView: View {
    @EnvironmentObject private var appState: AppState
    var onDismiss: () -> Void

    @State private var showContent = false
    @State private var folderPositions: [UUID: CGRect] = [:]

    var body: some View {
        GeometryReader { geo in
            let layout = gridLayout(for: geo.size)

            ZStack {
                // Background: blurred wallpaper
                wallpaperBackground.ignoresSafeArea()
                Color.black.opacity(0.25).ignoresSafeArea()
                    .onTapGesture { handleBackgroundTap() }

                // Content with scale animation
                VStack(spacing: 0) {
                    Spacer().frame(height: 48)
                    searchBar
                    Spacer().frame(height: 28)
                    gridView(layout: layout, screenSize: geo.size)
                    Spacer().frame(height: 12)
                    bottomBar.padding(.bottom, 16)
                }
                .scaleEffect(showContent ? 1.0 : 0.92)
                .opacity(showContent ? 1.0 : 0)

                // Folder overlay
                folderOverlayLayer

                // Delete confirmation (jiggle mode)
                deleteConfirmOverlay

                // Trash confirmation (right-click menu)
                trashConfirmOverlay
            }
            .onExitCommand {
                if appState.showTrashConfirm {
                    appState.cancelTrash()
                } else if appState.showDeleteConfirm {
                    appState.cancelDelete()
                } else if appState.isJiggling {
                    appState.exitJiggleMode()
                } else if appState.expandedFolderID != nil {
                    appState.expandedFolderID = nil
                } else {
                    dismissLaunchpad()
                }
            }
            .onAppear {
                withAnimation(.spring(duration: 0.3, bounce: 0.08)) { showContent = true }
            }
            .onChange(of: appState.isVisible) { _, v in
                if v { withAnimation(.spring(duration: 0.3, bounce: 0.08)) { showContent = true } }
            }
        }
    }

    private func dismissLaunchpad() {
        withAnimation(.easeIn(duration: 0.15)) { showContent = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            appState.exitJiggleMode()
            onDismiss()
        }
    }

    private func handleBackgroundTap() {
        if appState.showDeleteConfirm { appState.cancelDelete() }
        else if appState.isJiggling { appState.exitJiggleMode() }
        else if appState.expandedFolderID != nil { appState.expandedFolderID = nil }
        else { dismissLaunchpad() }
    }

    // MARK: - Wallpaper

    @ViewBuilder
    private var wallpaperBackground: some View {
        if let img = appState.wallpaperImage {
            Image(nsImage: img).resizable().aspectRatio(contentMode: .fill)
        } else {
            VisualEffectBlur()
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.5)).font(.system(size: 14))
            TextField(L10n.searchPlaceholder, text: $appState.searchText)
                .textFieldStyle(.plain).font(.system(size: 15)).foregroundStyle(.white)
                .onSubmit {
                    if let first = appState.filteredGridItems.first {
                        appState.launchItem(first); onDismiss()
                    }
                }
            if !appState.searchText.isEmpty {
                Button { appState.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.4))
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.12), lineWidth: 0.5))
        )
        .frame(width: 260)
    }

    // MARK: - Grid

    private struct GridLayout {
        let columns: Int, iconSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat
    }

    private func gridLayout(for size: NSSize) -> GridLayout {
        let uw = size.width - 100, uh = size.height - 200
        let cols = max(5, Int(uw / 120))
        let rows = max(3, Int(uh / 110))
        let cw = uw / CGFloat(cols), ch = uh / CGFloat(rows)
        let icon = min(cw * 0.55, ch * 0.52, 68)
        return GridLayout(columns: cols, iconSize: icon, cellWidth: cw, cellHeight: ch)
    }

    @ViewBuilder
    private func gridView(layout: GridLayout, screenSize: NSSize) -> some View {
        let items = appState.filteredGridItems
        let cols = Array(repeating: GridItem(.fixed(layout.cellWidth), spacing: 0), count: layout.columns)
        let vs = max(0, layout.cellHeight - layout.iconSize - 30)

        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: cols, spacing: vs) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    gridCell(item, iconSize: layout.iconSize)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.5)
                        .animation(
                            .spring(duration: 0.35, bounce: 0.1)
                            .delay(min(Double(index) * 0.006, 0.2)),
                            value: showContent
                        )
                        .background(GeometryReader { g in
                            Color.clear.onAppear {
                                if item.kind == .folder {
                                    let frame = g.frame(in: .global)
                                    folderPositions[item.id] = frame
                                }
                            }
                        })
                }
            }
            .padding(.horizontal, 50)
            .animation(.spring(duration: 0.2, bounce: 0.05), value: items.map(\.id))
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { handleBackgroundTap() }
    }

    @ViewBuilder
    private func gridCell(_ item: LaunchItem, iconSize: CGFloat) -> some View {
        switch item.kind {
        case .folder:
            FolderThumbnailView(folder: item, iconSize: iconSize) {
                appState.expandedFolderID = item.id
            }
            .dropDestination(for: String.self) { ids, _ in
                // Drop on folder → add item into folder
                guard let s = ids.first, let did = UUID(uuidString: s), did != item.id else {
                    appState.endDrag(); return false
                }
                if let d = appState.gridItems.first(where: { $0.id == did }), d.kind != .folder {
                    appState.addToFolder(item: d, folderID: item.id)
                }
                appState.endDrag()
                return true
            } isTargeted: { t in
                // Hover over folder → reorder to this position
                if t, let did = appState.draggingItemID {
                    appState.moveItem(fromID: did, toID: item.id)
                }
                appState.dragTargetID = t ? item.id : nil
            }
        case .app, .url:
            AppIconView(
                item: item,
                iconImage: appState.iconCache.icon(for: item),
                iconSize: iconSize,
                isDropTarget: appState.dragTargetID == item.id,
                onLaunch: { appState.launchItem(item); dismissLaunchpad() }
            )
            .dropDestination(for: String.self) { ids, _ in
                // Drop on app icon → create folder
                guard let s = ids.first, let did = UUID(uuidString: s), did != item.id else {
                    appState.endDrag(); return false
                }
                if let d = appState.gridItems.first(where: { $0.id == did }) {
                    appState.createFolder(from: d, and: item)
                }
                appState.endDrag()
                return true
            } isTargeted: { t in
                // Hover over icon → reorder to this position
                if t, let did = appState.draggingItemID {
                    appState.moveItem(fromID: did, toID: item.id)
                }
                appState.dragTargetID = t ? item.id : nil
            }
        }
    }

    // MARK: - Folder Overlay

    private var isOverlayVisible: Bool { appState.expandedFolderID != nil }
    private var currentFolder: LaunchItem? {
        guard let id = appState.expandedFolderID else { return nil }
        return appState.gridItems.first { $0.id == id }
    }

    @ViewBuilder
    private var folderOverlayLayer: some View {
        ZStack {
            Color.black.opacity(isOverlayVisible ? 0.3 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(isOverlayVisible)
                .onTapGesture { appState.expandedFolderID = nil }
                .animation(.easeOut(duration: 0.15), value: isOverlayVisible)

            if let folder = currentFolder {
                FolderExpandedView(
                    folder: folder,
                    onClose: { appState.expandedFolderID = nil },
                    onLaunchChild: { c in appState.launchItem(c); dismissLaunchpad() },
                    onRemoveChild: { c in appState.removeFromFolder(item: c, folderID: folder.id) },
                    onRename: { n in appState.renameFolder(id: folder.id, newName: n) }
                )
                .scaleEffect(isOverlayVisible ? 1.0 : 0.5)
                .opacity(isOverlayVisible ? 1.0 : 0)
                .animation(.spring(duration: 0.25, bounce: 0.15), value: isOverlayVisible)
            }
        }
        .allowsHitTesting(isOverlayVisible)
    }

    // MARK: - Delete Confirmation (for jiggle mode × button)

    @ViewBuilder
    private var deleteConfirmOverlay: some View {
        if appState.showDeleteConfirm, let item = appState.pendingDeleteItem {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                    .onTapGesture { appState.cancelDelete() }

                VStack(spacing: 16) {
                    Image(nsImage: appState.iconCache.icon(for: item))
                        .resizable().frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(L10n.removeTitle(item.name))
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)

                    Text(L10n.removeMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button(L10n.cancel) { appState.cancelDelete() }
                            .keyboardShortcut(.cancelAction)
                        Button(L10n.remove) { appState.confirmDelete() }
                            .keyboardShortcut(.defaultAction)
                    }
                    .controlSize(.regular)
                }
                .padding(24)
                .frame(width: 300)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor)))
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
    }

    // MARK: - Trash Confirmation (for right-click Move to Trash)

    @ViewBuilder
    private var trashConfirmOverlay: some View {
        if appState.showTrashConfirm, let item = appState.pendingTrashItem {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                    .onTapGesture { appState.cancelTrash() }

                VStack(spacing: 16) {
                    Image(nsImage: appState.iconCache.icon(for: item))
                        .resizable().frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(L10n.trashTitle(item.name))
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)

                    Text(L10n.trashMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button(L10n.cancel) { appState.cancelTrash() }
                            .keyboardShortcut(.cancelAction)
                        Button(L10n.moveToTrashButton) { appState.confirmTrash() }
                            .keyboardShortcut(.defaultAction)
                            .tint(.red)
                    }
                    .controlSize(.regular)
                }
                .padding(24)
                .frame(width: 320)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor)))
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Spacer()
            Button { NSApp.terminate(nil) } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power"); Text(L10n.quit)
                }
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 50)
    }
}

// MARK: - Fallback blur

struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .fullScreenUI; v.blendingMode = .behindWindow; v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
