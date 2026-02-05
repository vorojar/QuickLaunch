import Foundation

struct AppUsageRecord: Codable, Identifiable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    var launchCount: Int
    var activationCount: Int
    var lastUsed: Date

    init(bundleIdentifier: String, launchCount: Int = 0, activationCount: Int = 0, lastUsed: Date = Date()) {
        self.bundleIdentifier = bundleIdentifier
        self.launchCount = launchCount
        self.activationCount = activationCount
        self.lastUsed = lastUsed
    }

    var score: Double {
        // Weighted score: launches matter more, recency provides a boost
        let daysSinceUse = max(1, -lastUsed.timeIntervalSinceNow / 86400)
        let recencyBoost = 1.0 / log2(daysSinceUse + 1)
        return Double(launchCount * 3 + activationCount) * recencyBoost
    }
}
