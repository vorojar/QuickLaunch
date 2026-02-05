import AppKit
import SwiftUI
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var launchpadWindow: LaunchpadWindow?
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = AppState.shared // trigger init (preloads icons + starts directory monitoring)
        setAppIcon()
        setupMinimalMenu()
        setupStatusItem()
        launchpadWindow = LaunchpadWindow()
        registerGlobalHotKey()
    }

    /// Hide default menu bar, only keep essential Quit shortcut
    private func setupMinimalMenu() {
        let mainMenu = NSMenu()

        // App menu (required for ⌘Q to work)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: L10n.menuQuit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func setAppIcon() {
        // Set Dock icon from bundled icns
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }
    }

    // Dock click
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        launchpadWindow?.toggle()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }

        // Load custom rocket icon from bundle
        if let iconPath = Bundle.main.path(forResource: "StatusBarIcon", ofType: "png"),
           let icon = NSImage(contentsOfFile: iconPath) {
            icon.isTemplate = true  // Allows system to adapt color for dark/light mode
            icon.size = NSSize(width: 18, height: 18)
            button.image = icon
        } else {
            // Fallback to SF Symbol
            button.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "QuickLaunch")
        }

        button.action = #selector(statusItemClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: L10n.menuShow, action: #selector(showLaunchpad), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L10n.menuAutoOrganize, action: #selector(autoOrganize), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L10n.menuRescan, action: #selector(rescanApps), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L10n.menuAbout, action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L10n.menuQuit, action: #selector(quitApp), keyEquivalent: "q"))
        self.statusMenu = menu
    }

    private var statusMenu: NSMenu?

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            if let menu = statusMenu, let button = statusItem?.button {
                statusItem?.menu = menu
                button.performClick(nil)
                statusItem?.menu = nil
            }
        } else {
            launchpadWindow?.toggle()
        }
    }

    @objc private func showLaunchpad() { launchpadWindow?.show() }

    @objc private func autoOrganize() {
        AppState.shared.autoOrganize()
    }

    @objc private func rescanApps() {
        let s = AppState.shared
        s.gridItems = s.appScanner.scanApplications()
        s.sortByUsage()
        s.save()
    }

    @objc private func quitApp() { NSApp.terminate(nil) }

    @objc private func showAbout() {
        launchpadWindow?.hide()
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = L10n.aboutTitle
        alert.informativeText = "\(L10n.aboutDescription)\n\n\(L10n.aboutVersion("1.0.0"))"
        alert.alertStyle = .informational

        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            alert.icon = icon
        }

        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Global Hot Key

    private func registerGlobalHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x514C), id: 1)
        var ref: EventHotKeyRef?
        RegisterEventHotKey(49, UInt32(cmdKey | shiftKey), hotKeyID, GetApplicationEventTarget(), 0, &ref)
        hotKeyRef = ref

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData -> OSStatus in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let d = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { d.launchpadWindow?.toggle() }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
    }
}

// MARK: - KeyableWindow

final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Launchpad Window

final class LaunchpadWindow {
    private var window: KeyableWindow?
    private let appState = AppState.shared
    private var isAnimating = false

    func toggle() {
        guard !isAnimating else { return }
        if let w = window, w.isVisible { hide() } else { show() }
    }

    func show() {
        if window == nil { createWindow() }
        guard let w = window, let screen = NSScreen.main else { return }
        isAnimating = true
        appState.captureWallpaper() // refresh wallpaper each time
        w.setFrame(screen.frame, display: false)
        w.alphaValue = 0
        w.makeKeyAndOrderFront(nil)
        w.makeFirstResponder(w.contentView)
        NSApp.activate(ignoringOtherApps: true)

        appState.searchText = ""
        appState.expandedFolderID = nil
        appState.exitJiggleMode()
        appState.isVisible = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            w.animator().alphaValue = 1
        } completionHandler: { [weak self] in self?.isAnimating = false }
    }

    func hide() {
        guard let w = window else { return }
        isAnimating = true
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            w.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            w.orderOut(nil)
            self?.appState.isVisible = false
            self?.appState.exitJiggleMode()
            self?.isAnimating = false
        })
    }

    private func createWindow() {
        let w = KeyableWindow(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.level = .init(rawValue: NSWindow.Level.mainMenu.rawValue - 1)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        w.isMovableByWindowBackground = false
        w.acceptsMouseMovedEvents = true

        let hosting = NSHostingView(
            rootView: LaunchpadRootView(onDismiss: { [weak self] in self?.hide() })
                .environmentObject(appState)
        )
        hosting.wantsLayer = true
        hosting.layer?.drawsAsynchronously = true
        w.contentView = hosting
        self.window = w
    }
}
