import Foundation

struct RenamingError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

final class RenamingService {
    private let fileManager = FileManager.default
    private let reviewFolderName = "Review"
    private let maxFilenameLength = 70

    func apply(metadata: DocumentMetadata, to fileURL: URL, in rootFolder: URL) throws -> ProcessingOutcome {
        guard let subjectComponent = metadata.subject?.normalizedFilenameComponent,
              !subjectComponent.isEmpty
        else {
            return try moveToReview(url: fileURL, in: rootFolder)
        }

        guard let date = metadata.date ?? fileURL.creationDate else {
            return try moveToReview(url: fileURL, in: rootFolder)
        }

        let normalizedDate = DateFormatter.cached(format: "yyyy-MM-dd").string(from: date)
        let proposedName = String("\(normalizedDate)_\(subjectComponent)".prefix(maxFilenameLength))
        let destinationURL = uniqueURL(for: proposedName, ext: "pdf", in: rootFolder)

        try fileManager.moveItem(at: fileURL, to: destinationURL)
        return .renamed(newURL: destinationURL)
    }

    private func moveToReview(url: URL, in rootFolder: URL) throws -> ProcessingOutcome {
        let reviewURL = rootFolder.appending(path: reviewFolderName, directoryHint: .isDirectory)
        if !fileManager.fileExists(atPath: reviewURL.path) {
            try fileManager.createDirectory(at: reviewURL, withIntermediateDirectories: true)
        }
        let baseName = "0000-00-00_Review_\(url.deletingPathExtension().lastPathComponent.normalizedFilenameComponent)"
        let destinationURL = uniqueURL(for: baseName, ext: "pdf", in: reviewURL)
        try fileManager.moveItem(at: url, to: destinationURL)
        return .movedToReview(reviewURL: destinationURL)
    }

    private func uniqueURL(for baseName: String, ext: String, in folder: URL) -> URL {
        var candidate = folder.appending(path: baseName).appendingPathExtension(ext)
        var index = 1
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = folder.appending(path: "\(baseName)_\(index)").appendingPathExtension(ext)
            index += 1
        }
        return candidate
    }
}

private extension String {
    var normalizedFilenameComponent: String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_ ")
        let mapped = unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        var candidate = String(mapped).replacingOccurrences(of: " ", with: "_")
        candidate = candidate.replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
        candidate = candidate.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return candidate
    }
}

private extension DateFormatter {
    static func cached(format: String) -> DateFormatter {
        struct Cache {
            static var formatterDictionary: [String: DateFormatter] = [:]
        }
        if let formatter = Cache.formatterDictionary[format] {
            return formatter
        }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        Cache.formatterDictionary[format] = formatter
        return formatter
    }
}

private extension URL {
    var creationDate: Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.creationDate] as? Date
    }
}
