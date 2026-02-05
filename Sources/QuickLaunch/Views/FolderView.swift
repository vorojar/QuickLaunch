import SwiftUI

// MARK: - Folder Thumbnail (in grid)

struct FolderThumbnailView: View {
    let folder: LaunchItem
    let iconSize: CGFloat
    var onTap: () -> Void

    @EnvironmentObject private var appState: AppState
    @State private var isHovering = false

    var children: [LaunchItem] { folder.children ?? [] }

    private var jigglePhase: Double {
        Double(folder.id.hashValue & 0xFF) / 255.0
    }

    var body: some View {
        Button(action: {
            if appState.isJiggling { return }
            onTap()
        }) {
            VStack(spacing: 5) {
                ZStack(alignment: .topLeading) {
                    ZStack {
                        RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous)
                            .fill(.white.opacity(0.18))
                            .frame(width: iconSize, height: iconSize)

                        let previews = Array(children.prefix(4))
                        let mini = iconSize * 0.36
                        LazyVGrid(
                            columns: [GridItem(.fixed(mini), spacing: 2), GridItem(.fixed(mini), spacing: 2)],
                            spacing: 2
                        ) {
                            ForEach(previews) { child in
                                Image(nsImage: appState.iconCache.icon(for: child))
                                    .resizable()
                                    .interpolation(.high)
                                    .frame(width: mini, height: mini)
                                    .clipShape(RoundedRectangle(cornerRadius: mini * 0.18, style: .continuous))
                            }
                        }
                    }
                    .scaleEffect(isHovering && !appState.isJiggling ? 1.08 : 1.0)

                    if appState.isJiggling {
                        Button {
                            appState.requestDelete(folder)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .gray.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        .offset(x: -5, y: -5)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: iconSize + 10, height: iconSize + 10)

                Text(folder.name)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.7), radius: 3, y: 1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .modifier(JiggleModifier(isJiggling: appState.isJiggling, phase: jigglePhase))
        .onLongPressGesture(minimumDuration: 0.5) {
            appState.enterJiggleMode()
        }
        .onDrag {
            appState.draggingItemID = folder.id
            if !appState.isJiggling { appState.enterJiggleMode() }
            return NSItemProvider(object: folder.id.uuidString as NSString)
        }
        .contextMenu {
            Button {
                appState.expandedFolderID = folder.id
            } label: {
                Label(L10n.rename, systemImage: "pencil")
            }

            Divider()

            Button {
                appState.dissolveFolder(id: folder.id)
            } label: {
                Label(L10n.dissolveFolder, systemImage: "folder.badge.minus")
            }
        }
    }
}

// MARK: - Folder Expanded (centered overlay)

struct FolderExpandedView: View {
    let folder: LaunchItem
    var onClose: () -> Void
    var onLaunchChild: (LaunchItem) -> Void
    var onRemoveChild: (LaunchItem) -> Void
    var onRename: (String) -> Void

    @EnvironmentObject private var appState: AppState
    @State private var isEditingName = true  // auto-edit on open
    @State private var editText: String = ""
    @FocusState private var nameFieldFocused: Bool

    var children: [LaunchItem] { folder.children ?? [] }

    var body: some View {
        VStack(spacing: 16) {
            // Folder name — auto-editable
            if isEditingName {
                TextField(L10n.folderNamePlaceholder, text: $editText, onCommit: {
                    if !editText.isEmpty { onRename(editText) }
                    isEditingName = false
                })
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(width: 220)
                .focused($nameFieldFocused)
                .onAppear {
                    editText = folder.name
                    // Delay focus so view is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        nameFieldFocused = true
                    }
                }
            } else {
                Text(folder.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .onTapGesture {
                        editText = folder.name
                        isEditingName = true
                    }
            }

            // Children grid
            let colCount = min(max(children.count, 2), 5)
            let cols = Array(repeating: GridItem(.fixed(90), spacing: 12), count: colCount)

            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(children) { child in
                    AppIconView(
                        item: child,
                        iconImage: appState.iconCache.icon(for: child),
                        iconSize: 52,
                        showContextMenu: false,
                        onLaunch: { onLaunchChild(child) }
                    )
                    .onDrag {
                        // Drag out of folder: remove child, close folder
                        onRemoveChild(child)
                        onClose()
                        return NSItemProvider(object: child.id.uuidString as NSString)
                    }
                    .contextMenu {
                        Button {
                            onRemoveChild(child)
                        } label: {
                            Label(L10n.removeFromFolder, systemImage: "folder.badge.minus")
                        }

                        Divider()

                        Button {
                            if let path = child.path {
                                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                            }
                        } label: {
                            Label(L10n.showInFinder, systemImage: "folder")
                        }

                        Button {
                            if let path = child.path {
                                let script = """
                                tell application "Finder"
                                    open information window of (POSIX file "\(path)" as alias)
                                    activate
                                end tell
                                """
                                if let appleScript = NSAppleScript(source: script) {
                                    appleScript.executeAndReturnError(nil)
                                }
                            }
                        } label: {
                            Label(L10n.getInfo, systemImage: "info.circle")
                        }

                        Divider()

                        Button {
                            appState.hideFromLaunchpad(child)
                        } label: {
                            Label(L10n.removeFromLaunchpad, systemImage: "minus.circle")
                        }

                        Button(role: .destructive) {
                            appState.requestTrash(child)
                        } label: {
                            Label(L10n.moveToTrash, systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(minWidth: 280, maxWidth: 520)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.92))
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .padding(12),
            alignment: .topTrailing
        )
    }
}
