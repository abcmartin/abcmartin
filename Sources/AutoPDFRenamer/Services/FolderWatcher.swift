import CoreServices
import Foundation

final class FolderWatcher {
    private let folderURL: URL
    private let handler: (URL) -> Void
    private var streamRef: FSEventStreamRef?

    init(folderURL: URL, handler: @escaping (URL) -> Void) {
        self.folderURL = folderURL
        self.handler = handler
    }

    func start() {
        let callback: FSEventStreamCallback = { _, info, numEvents, eventPaths, eventFlags, _ in
            guard let info else { return }
            let watcher = Unmanaged<FolderWatcher>.fromOpaque(info).takeUnretainedValue()
            let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
            for index in 0..<numEvents {
                let flag = eventFlags[index]
                let path = paths[index]
                let url = URL(fileURLWithPath: path)
                if watcher.isRelevant(flag: flag, url: url) {
                    watcher.handler(url)
                }
            }
        }

        var context = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        streamRef = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            [folderURL.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        if let streamRef {
            FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(streamRef)
        }
    }

    private func isRelevant(flag: FSEventStreamEventFlags, url: URL) -> Bool {
        guard url.pathExtension.lowercased() == "pdf" else { return false }
        let fileFlag = FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile)
        let activityFlags = FSEventStreamEventFlags(
            kFSEventStreamEventFlagItemCreated |
                kFSEventStreamEventFlagItemRenamed |
                kFSEventStreamEventFlagItemModified
        )
        let itemIsFile = flag & fileFlag != 0
        let wasUpdated = flag & activityFlags != 0
        return itemIsFile && wasUpdated
    }

    deinit {
        if let streamRef {
            FSEventStreamStop(streamRef)
            FSEventStreamInvalidate(streamRef)
            FSEventStreamRelease(streamRef)
        }
    }
}
