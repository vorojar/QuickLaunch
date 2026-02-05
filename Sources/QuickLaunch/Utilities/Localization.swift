import Foundation

/// Localization helper - automatically uses system language
enum L10n {
    private static let isChinese: Bool = {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("zh")
    }()

    // MARK: - Menu Items
    static var menuShow: String { isChinese ? "显示 QuickLaunch" : "Show QuickLaunch" }
    static var menuAutoOrganize: String { isChinese ? "自动整理" : "Auto Organize" }
    static var menuRescan: String { isChinese ? "重新扫描" : "Rescan Apps" }
    static var menuAbout: String { isChinese ? "关于 QuickLaunch" : "About QuickLaunch" }
    static var menuQuit: String { isChinese ? "退出 QuickLaunch" : "Quit QuickLaunch" }

    // MARK: - Search
    static var searchPlaceholder: String { isChinese ? "搜索" : "Search" }

    // MARK: - Context Menu
    static var showInFinder: String { isChinese ? "在 Finder 中显示" : "Show in Finder" }
    static var getInfo: String { isChinese ? "显示简介" : "Get Info" }
    static var removeFromLaunchpad: String { isChinese ? "从启动台移除" : "Remove from LaunchPad" }
    static var moveToTrash: String { isChinese ? "移到废纸篓" : "Move to Trash" }
    static var rename: String { isChinese ? "重命名" : "Rename" }
    static var dissolveFolder: String { isChinese ? "解散文件夹" : "Dissolve Folder" }
    static var removeFromFolder: String { isChinese ? "从文件夹移除" : "Remove from Folder" }

    // MARK: - Folder
    static var folderNamePlaceholder: String { isChinese ? "文件夹名称" : "Folder name" }
    static var newFolder: String { isChinese ? "新建文件夹" : "New Folder" }

    // MARK: - Dialogs
    static var cancel: String { isChinese ? "取消" : "Cancel" }
    static var remove: String { isChinese ? "移除" : "Remove" }
    static var moveToTrashButton: String { isChinese ? "移到废纸篓" : "Move to Trash" }

    static func removeTitle(_ name: String) -> String {
        isChinese ? "从启动台移除「\(name)」？" : "Remove \"\(name)\" from LaunchPad?"
    }
    static var removeMessage: String {
        isChinese ? "应用将保留在「应用程序」文件夹中。" : "The app will remain in your Applications folder."
    }

    static func trashTitle(_ name: String) -> String {
        isChinese ? "将「\(name)」移到废纸篓？" : "Move \"\(name)\" to Trash?"
    }
    static var trashMessage: String {
        isChinese ? "应用将被移到废纸篓，可从废纸篓恢复。" : "The app will be moved to Trash and can be restored from there."
    }

    // MARK: - Bottom Bar
    static var quit: String { isChinese ? "退出" : "Quit" }

    // MARK: - About
    static var aboutTitle: String { isChinese ? "关于 QuickLaunch" : "About QuickLaunch" }
    static var aboutDescription: String {
        isChinese ? "macOS 快捷启动器\n按 ⌘⇧Space 呼出" : "A fast app launcher for macOS.\nPress ⌘⇧Space to launch."
    }
    static func aboutVersion(_ version: String) -> String {
        isChinese ? "版本 \(version)" : "Version \(version)"
    }
}
