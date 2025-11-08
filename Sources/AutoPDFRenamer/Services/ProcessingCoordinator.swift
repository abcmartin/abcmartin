import Foundation

final class ProcessingCoordinator {
    private let folderURL: URL
    private let queue = ProcessingQueue()
    private let metadataExtractor: MetadataExtraction
    private let textAcquisition: TextAcquisition
    private let renamer: RenamingService
    private let statusHandler: (ProcessingStatus) -> Void
    private var watcher: FolderWatcher?

    init(
        folderURL: URL,
        metadataExtractor: MetadataExtraction = MetadataExtraction(),
        textAcquisition: TextAcquisition = TextAcquisition(),
        renamer: RenamingService = RenamingService(),
        statusHandler: @escaping (ProcessingStatus) -> Void
    ) {
        self.folderURL = folderURL
        self.metadataExtractor = metadataExtractor
        self.textAcquisition = textAcquisition
        self.renamer = renamer
        self.statusHandler = statusHandler
    }

    func start() {
        watcher = FolderWatcher(folderURL: folderURL) { [weak self] url in
            self?.enqueue(url: url)
        }
        watcher?.start()
    }

    private func enqueue(url: URL) {
        guard shouldProcess(url: url) else { return }
        statusHandler(.queued(url))
        queue.enqueue(url) { [weak self] url in
            guard let self else { return }
            self.process(url: url)
        }
    }

    private func shouldProcess(url: URL) -> Bool {
        let parent = url.deletingLastPathComponent()
        if parent.lastPathComponent == "Review" { return false }
        if parent != folderURL { return false }
        let name = url.lastPathComponent
        if name.hasPrefix(".") { return false }
        let normalizedPattern = #"^\d{4}-\d{2}-\d{2}_"#
        if name.range(of: normalizedPattern, options: .regularExpression) != nil {
            return false
        }
        return true
    }

    private func process(url: URL) {
        statusHandler(.processing(url))
        do {
            let extractedText = try textAcquisition.extractText(from: url)
            let metadata = metadataExtractor.extract(from: extractedText, fileURL: url)
            let outcome = try renamer.apply(metadata: metadata, to: url, in: folderURL)
            statusHandler(.completed(url, outcome))
        } catch {
            statusHandler(.completed(url, .failed(error: error)))
        }
    }
}

enum ProcessingStatus {
    case queued(URL)
    case processing(URL)
    case completed(URL, ProcessingOutcome)
}
