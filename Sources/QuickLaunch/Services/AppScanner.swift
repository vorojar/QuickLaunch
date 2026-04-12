import AppKit

final class AppScanner {
    private let searchPaths: [String] = [
        "/Applications",
        "/System/Applications",
        NSHomeDirectory() + "/Applications"
    ]

    func scanApplications() -> [LaunchItem] {
        var items: [LaunchItem] = []
        var seenBIDs = Set<String>()
        let fm = FileManager.default

        for searchPath in searchPaths {
            scanDirectory(searchPath, fm: fm, items: &items, seenBIDs: &seenBIDs, depth: 0)
        }

        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Recursively scan directory for .app bundles (max depth 3 to avoid going too deep).
    private func scanDirectory(_ path: String, fm: FileManager, items: inout [LaunchItem], seenBIDs: inout Set<String>, depth: Int) {
        guard depth <= 3 else { return }
        guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return }

        for entry in contents {
            let fullPath = (path as NSString).appendingPathComponent(entry)

            if entry.hasSuffix(".app") {
                if let item = makeItem(from: fullPath) {
                    // Deduplicate by bundle ID
                    if let bid = item.bundleIdentifier {
                        guard !seenBIDs.contains(bid) else { continue }
                        seenBIDs.insert(bid)
                    }
                    items.append(item)
                }
            } else {
                // Recurse into subdirectories (e.g. Utilities/)
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                    scanDirectory(fullPath, fm: fm, items: &items, seenBIDs: &seenBIDs, depth: depth + 1)
                }
            }
        }
    }

    private func makeItem(from path: String) -> LaunchItem? {
        guard let bundle = Bundle(path: path) else { return nil }

        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? ((path as NSString).lastPathComponent as NSString).deletingPathExtension

        let bundleID = bundle.bundleIdentifier

        // Read category from LSApplicationCategoryType
        var category = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String

        // Fallback: apps in Utilities folder
        if category == nil && path.contains("/Utilities/") {
            category = "public.app-category.utilities"
        }

        // Fallback: Apple apps
        if category == nil, let bid = bundleID, bid.hasPrefix("com.apple.") {
            category = "apple"
        }

        return LaunchItem(
            name: displayName,
            kind: .app,
            path: path,
            bundleIdentifier: bundleID,
            category: category
        )
    }

    /// Map category ID to localized folder name key, then resolve via L10n
    private static let categoryKeys: [String: String] = {
        var map: [String: String] = [
            "public.app-category.developer-tools": "developerTools",
            "public.app-category.productivity": "productivity",
            "public.app-category.utilities": "utilities",
            "public.app-category.social-networking": "social",
            "public.app-category.graphics-design": "design",
            "public.app-category.photography": "photography",
            "public.app-category.video": "video",
            "public.app-category.entertainment": "entertainment",
            "public.app-category.music": "music",
            "public.app-category.education": "education",
            "public.app-category.finance": "finance",
            "public.app-category.business": "business",
            "public.app-category.news": "news",
            "public.app-category.reference": "reference",
            "public.app-category.travel": "travel",
            "public.app-category.weather": "weather",
            "public.app-category.lifestyle": "lifestyle",
            "public.app-category.medical": "medical",
            "public.app-category.healthcare-fitness": "health",
            "public.app-category.food-drink": "foodDrink",
            "public.app-category.books": "books",
            "public.app-category.navigation": "navigation",
            "public.app-category.sports": "sports",
            "apple": "apple",
        ]
        // All game subcategories map to "games"
        let gameCategories = [
            "public.app-category.games",
            "public.app-category.action-games",
            "public.app-category.adventure-games",
            "public.app-category.arcade-games",
            "public.app-category.board-games",
            "public.app-category.card-games",
            "public.app-category.casino-games",
            "public.app-category.dice-games",
            "public.app-category.educational-games",
            "public.app-category.family-games",
            "public.app-category.kids-games",
            "public.app-category.music-games",
            "public.app-category.puzzle-games",
            "public.app-category.racing-games",
            "public.app-category.role-playing-games",
            "public.app-category.simulation-games",
            "public.app-category.sports-games",
            "public.app-category.strategy-games",
            "public.app-category.trivia-games",
            "public.app-category.word-games",
        ]
        for cat in gameCategories { map[cat] = "games" }
        return map
    }()

    static func folderName(for category: String?) -> String? {
        guard let cat = category, let key = categoryKeys[cat] else { return nil }
        return L10n.categoryName(key)
    }

    /// Returns a map from every possible localized folder name (all languages) to its category key.
    /// Used for migrating folder names when the system language changes.
    static func allLocalizedFolderNames() -> [String: String] {
        var result: [String: String] = [:]
        let uniqueKeys = Set(categoryKeys.values)
        for key in uniqueKeys {
            // Add both Chinese and English names mapping to the same key
            let zh = L10n.categoryName(key, forceLanguage: "zh")
            let en = L10n.categoryName(key, forceLanguage: "en")
            result[zh] = key
            result[en] = key
        }
        return result
    }
}
