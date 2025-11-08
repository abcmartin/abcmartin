import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class ProcessingLogViewModel: ObservableObject {
    @Published var logEntries: [LogEntry] = []
    @Published var selectedFolder: URL?

    private var coordinator: ProcessingCoordinator?

    func startIfNeeded() {
        guard coordinator == nil, let url = selectedFolder else {
            return
        }
        startProcessing(for: url)
    }

    func promptForFolderSelection() {
        let panel = NSOpenPanel()
        panel.title = "Select Inbox Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            selectedFolder = url
            startProcessing(for: url)
        }
    }

    private func startProcessing(for url: URL) {
        coordinator = ProcessingCoordinator(folderURL: url) { [weak self] status in
            Task { @MainActor in
                self?.append(status: status)
            }
        }
        coordinator?.start()
        logEntries.insert(LogEntry(title: "Watching", details: url.path), at: 0)
        trimLogIfNeeded()
    }

    private func append(status: ProcessingStatus) {
        logEntries.insert(status.logEntry, at: 0)
        trimLogIfNeeded()
    }

    private func trimLogIfNeeded() {
        if logEntries.count > 50 {
            logEntries.removeLast(logEntries.count - 50)
        }
    }
}

private extension ProcessingStatus {
    var logEntry: LogEntry {
        switch self {
        case let .queued(url):
            return LogEntry(title: "Queued", details: url.lastPathComponent)
        case let .processing(url):
            return LogEntry(title: "Processing", details: url.lastPathComponent)
        case let .completed(url, outcome):
            switch outcome {
            case let .renamed(newURL):
                return LogEntry(
                    title: "Renamed",
                    details: "\(url.lastPathComponent) → \(newURL.lastPathComponent)"
                )
            case let .movedToReview(reviewURL):
                return LogEntry(
                    title: "Review",
                    details: "\(url.lastPathComponent) → \(reviewURL.lastPathComponent)"
                )
            case let .failed(error):
                return LogEntry(
                    title: "Failed",
                    details: "\(url.lastPathComponent): \(error.localizedDescription)"
                )
            }
        }
    }
}
