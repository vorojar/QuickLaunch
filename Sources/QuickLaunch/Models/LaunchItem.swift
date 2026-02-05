import Foundation

struct LaunchItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var kind: Kind
    var path: String?
    var bundleIdentifier: String?
    var category: String?  // LSApplicationCategoryType for auto-organize
    var children: [LaunchItem]?

    enum Kind: String, Codable {
        case app
        case url
        case folder
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: Kind,
        path: String? = nil,
        bundleIdentifier: String? = nil,
        category: String? = nil,
        children: [LaunchItem]? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.path = path
        self.bundleIdentifier = bundleIdentifier
        self.category = category
        self.children = children
    }

    func matchesSearch(_ query: String) -> Bool {
        if name.lowercased().contains(query) { return true }
        if let bid = bundleIdentifier, bid.lowercased().contains(query) { return true }

        // Pinyin initial matching for Chinese names
        let initials = pinyinInitials(for: name)
        if !initials.isEmpty && initials.contains(query) { return true }

        // Check folder children
        if let children {
            return children.contains { $0.matchesSearch(query) }
        }
        return false
    }

    private func pinyinInitials(for text: String) -> String {
        let mutableString = NSMutableString(string: text)
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
        let words = (mutableString as String).split(separator: " ")
        return words.compactMap { $0.first }.map { String($0).lowercased() }.joined()
    }

    // Hashable conformance (exclude children to avoid recursion issues)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LaunchItem, rhs: LaunchItem) -> Bool {
        lhs.id == rhs.id
    }
}
