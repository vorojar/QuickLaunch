import AppKit

@main
enum AppMain {
    static func main() {
        // Prevent multiple instances — activate existing one if already running
        if let running = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "").first(where: { $0 != .current }) {
            running.activate()
            return
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
