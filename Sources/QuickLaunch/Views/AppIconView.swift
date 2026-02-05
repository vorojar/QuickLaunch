import SwiftUI

struct AppIconView: View {
    let item: LaunchItem
    let iconImage: NSImage
    var iconSize: CGFloat = 64
    var isDropTarget: Bool = false
    var showContextMenu: Bool = true  // Set to false when used inside folder (folder provides its own menu)
    var onLaunch: () -> Void

    @EnvironmentObject private var appState: AppState
    @State private var isHovering = false

    // Each icon gets a unique jiggle phase so they don't wobble in sync
    private var jigglePhase: Double {
        Double(item.id.hashValue & 0xFF) / 255.0
    }

    var body: some View {
        Button(action: {
            if appState.isJiggling { return }
            onLaunch()
        }) {
            VStack(spacing: 5) {
                ZStack(alignment: .topLeading) {
                    Image(nsImage: iconImage)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous))
                        .drawingGroup(opaque: false) // Metal-accelerated rendering
                        .scaleEffect(isHovering && !appState.isJiggling ? 1.08 : 1.0)

                    // Delete button in jiggle mode
                    if appState.isJiggling {
                        Button {
                            appState.requestDelete(item)
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

                Text(item.name)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.7), radius: 3, y: 1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDropTarget ? Color.white.opacity(0.2) : Color.clear)
        )
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .modifier(JiggleModifier(isJiggling: appState.isJiggling, phase: jigglePhase))
        .onLongPressGesture(minimumDuration: 0.5) {
            appState.enterJiggleMode()
        }
        .onDrag {
            appState.draggingItemID = item.id
            if !appState.isJiggling { appState.enterJiggleMode() }
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        .modifier(AppIconContextMenuModifier(item: item, showMenu: showContextMenu))
    }
}

// MARK: - Context Menu Modifier

struct AppIconContextMenuModifier: ViewModifier {
    let item: LaunchItem
    let showMenu: Bool
    @EnvironmentObject private var appState: AppState

    func body(content: Content) -> some View {
        if showMenu {
            content.contextMenu {
                Button {
                    if let path = item.path {
                        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                    }
                } label: {
                    Label(L10n.showInFinder, systemImage: "folder")
                }

                Button {
                    if let path = item.path {
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
                    appState.hideFromLaunchpad(item)
                } label: {
                    Label(L10n.removeFromLaunchpad, systemImage: "minus.circle")
                }

                Button(role: .destructive) {
                    appState.requestTrash(item)
                } label: {
                    Label(L10n.moveToTrash, systemImage: "trash")
                }
            }
        } else {
            content
        }
    }
}

// MARK: - Jiggle wobble animation

struct JiggleModifier: ViewModifier {
    let isJiggling: Bool
    let phase: Double

    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isJiggling ? angle : 0))
            .onChange(of: isJiggling) { _, jiggling in
                if jiggling {
                    startJiggle()
                } else {
                    angle = 0
                }
            }
            .onAppear {
                if isJiggling { startJiggle() }
            }
    }

    private func startJiggle() {
        let magnitude = 1.5 + phase * 1.0 // 1.5° ~ 2.5°
        // Start at a random phase
        angle = magnitude
        withAnimation(
            .easeInOut(duration: 0.1 + phase * 0.04)
            .repeatForever(autoreverses: true)
        ) {
            angle = -magnitude
        }
    }
}
