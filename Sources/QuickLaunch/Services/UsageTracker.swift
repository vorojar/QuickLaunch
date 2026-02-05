import AppKit
import Combine

final class UsageTracker {
    var records: [String: AppUsageRecord] = [:]
    var onAppLaunched: ((String) -> Void)?

    private var cancellables = Set<AnyCancellable>()

    func startTracking() {
        NotificationCenter.default.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .sink { [weak self] app in
                guard let bid = app.bundleIdentifier else { return }
                self?.recordLaunch(bundleIdentifier: bid)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .sink { [weak self] app in
                guard let bid = app.bundleIdentifier else { return }
                self?.recordActivation(bundleIdentifier: bid)
            }
            .store(in: &cancellables)
    }

    func recordLaunch(bundleIdentifier: String) {
        var record = records[bundleIdentifier] ?? AppUsageRecord(bundleIdentifier: bundleIdentifier)
        record.launchCount += 1
        record.lastUsed = Date()
        records[bundleIdentifier] = record
        onAppLaunched?(bundleIdentifier)
    }

    func recordActivation(bundleIdentifier: String) {
        var record = records[bundleIdentifier] ?? AppUsageRecord(bundleIdentifier: bundleIdentifier)
        record.activationCount += 1
        record.lastUsed = Date()
        records[bundleIdentifier] = record
    }

    func launchCount(for bundleIdentifier: String) -> Int {
        records[bundleIdentifier]?.launchCount ?? 0
    }

    func score(for bundleIdentifier: String) -> Double {
        records[bundleIdentifier]?.score ?? 0
    }
}
