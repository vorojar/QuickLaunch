import Foundation

final class DataStore {
    private let supportDir: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        supportDir = appSupport.appendingPathComponent("QuickLaunch", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
    }

    // MARK: - Grid Layout

    func saveGridLayout(_ items: [LaunchItem]) {
        save(items, to: "grid_layout.json")
    }

    func loadGridLayout() -> [LaunchItem]? {
        load([LaunchItem].self, from: "grid_layout.json")
    }

    // MARK: - Usage Stats

    func saveUsageStats(_ records: [String: AppUsageRecord]) {
        let array = Array(records.values)
        save(array, to: "usage_stats.json")
    }

    func loadUsageStats() -> [String: AppUsageRecord] {
        guard let array: [AppUsageRecord] = load([AppUsageRecord].self, from: "usage_stats.json") else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: array.map { ($0.bundleIdentifier, $0) })
    }

    // MARK: - Hidden Apps

    func saveHiddenApps(_ bundleIDs: Set<String>) {
        save(Array(bundleIDs), to: "hidden_apps.json")
    }

    func loadHiddenApps() -> Set<String> {
        guard let array: [String] = load([String].self, from: "hidden_apps.json") else {
            return []
        }
        return Set(array)
    }

    // MARK: - Settings

    func saveSetting<T: Encodable>(_ value: T, key: String) {
        var settings = loadAllSettings()
        if let data = try? JSONEncoder().encode(value) {
            settings[key] = String(data: data, encoding: .utf8)
        }
        save(settings, to: "settings.json")
    }

    private func loadAllSettings() -> [String: String] {
        load([String: String].self, from: "settings.json") ?? [:]
    }

    // MARK: - Generic JSON helpers

    private func save<T: Encodable>(_ value: T, to filename: String) {
        let url = supportDir.appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = supportDir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }
}
