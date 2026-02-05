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

    /// Map category ID to user-friendly folder name (Chinese)
    static let categoryNames: [String: String] = [
        "public.app-category.developer-tools": "开发工具",
        "public.app-category.productivity": "效率工具",
        "public.app-category.utilities": "实用工具",
        "public.app-category.social-networking": "社交",
        "public.app-category.graphics-design": "设计",
        "public.app-category.photography": "摄影",
        "public.app-category.video": "视频",
        "public.app-category.entertainment": "娱乐",
        "public.app-category.music": "音乐",
        "public.app-category.games": "游戏",
        "public.app-category.action-games": "游戏",
        "public.app-category.adventure-games": "游戏",
        "public.app-category.arcade-games": "游戏",
        "public.app-category.board-games": "游戏",
        "public.app-category.card-games": "游戏",
        "public.app-category.casino-games": "游戏",
        "public.app-category.dice-games": "游戏",
        "public.app-category.educational-games": "游戏",
        "public.app-category.family-games": "游戏",
        "public.app-category.kids-games": "游戏",
        "public.app-category.music-games": "游戏",
        "public.app-category.puzzle-games": "游戏",
        "public.app-category.racing-games": "游戏",
        "public.app-category.role-playing-games": "游戏",
        "public.app-category.simulation-games": "游戏",
        "public.app-category.sports-games": "游戏",
        "public.app-category.strategy-games": "游戏",
        "public.app-category.trivia-games": "游戏",
        "public.app-category.word-games": "游戏",
        "public.app-category.education": "教育",
        "public.app-category.finance": "财务",
        "public.app-category.business": "商务",
        "public.app-category.news": "新闻",
        "public.app-category.reference": "参考资料",
        "public.app-category.travel": "旅行",
        "public.app-category.weather": "天气",
        "public.app-category.lifestyle": "生活",
        "public.app-category.medical": "医疗",
        "public.app-category.healthcare-fitness": "健康",
        "public.app-category.food-drink": "美食",
        "public.app-category.books": "图书",
        "public.app-category.navigation": "导航",
        "public.app-category.sports": "体育",
        "apple": "Apple"
    ]

    static func folderName(for category: String?) -> String? {
        guard let cat = category else { return nil }
        return categoryNames[cat]
    }
}
