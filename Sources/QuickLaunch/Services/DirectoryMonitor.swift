import Foundation

/// Monitors directories for file system changes using GCD DispatchSource.
final class DirectoryMonitor {
    private var sources: [DispatchSourceFileSystemObject] = []
    private let onChange: () -> Void
    private let debounceInterval: TimeInterval = 1.5
    private var debounceWorkItem: DispatchWorkItem?

    init(paths: [String], onChange: @escaping () -> Void) {
        self.onChange = onChange
        for path in paths {
            startMonitoring(path: path)
        }
    }

    deinit {
        stopAll()
    }

    private func startMonitoring(path: String) {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            self?.handleChange()
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        sources.append(source)
    }

    private func handleChange() {
        // Debounce: apps may write multiple files during install/update
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.onChange()
        }
        debounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }

    func stopAll() {
        for source in sources { source.cancel() }
        sources.removeAll()
        debounceWorkItem?.cancel()
    }
}
