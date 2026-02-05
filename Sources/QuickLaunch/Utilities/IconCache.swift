import AppKit

final class IconCache: @unchecked Sendable {
    private var cache: [String: NSImage] = [:]
    private let lock = NSLock()
    private let renderSize: NSSize = NSSize(width: 128, height: 128)

    /// Returns a pre-rendered bitmap icon (thread-safe, cached).
    func icon(for item: LaunchItem) -> NSImage {
        if let path = item.path {
            lock.lock()
            let cached = cache[path]
            lock.unlock()
            if let cached { return cached }
        }

        guard let path = item.path else {
            return NSImage(systemSymbolName: "questionmark.app", accessibilityDescription: nil)
                ?? NSImage()
        }

        let raw = NSWorkspace.shared.icon(forFile: path)
        // Pre-render to bitmap at fixed size — avoids repeated PDF rasterization in SwiftUI
        let rendered = prerenderIcon(raw)

        lock.lock()
        cache[path] = rendered
        lock.unlock()
        return rendered
    }

    /// Preload icons for a batch of items on background thread.
    func preload(_ items: [LaunchItem]) {
        for item in items {
            _ = icon(for: item)
            // Also preload folder children
            if let children = item.children {
                for child in children { _ = icon(for: child) }
            }
        }
    }

    func clearCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }

    // Render icon to a fixed-size bitmap to avoid SwiftUI re-rasterizing vector/PDF icons every frame.
    private func prerenderIcon(_ source: NSImage) -> NSImage {
        let img = NSImage(size: renderSize)
        img.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(in: NSRect(origin: .zero, size: renderSize),
                    from: .zero,
                    operation: .copy,
                    fraction: 1.0)
        img.unlockFocus()
        img.cacheMode = .always
        return img
    }
}
