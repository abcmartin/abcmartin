import Foundation

struct DocumentMetadata {
    let subject: String?
    let date: Date?
    let rawText: String
}

struct MetadataExtraction {
    private static let subjectMarkers = ["betreff", "betr.", "subject"]
    private static let allowedSubjectLength = 5...80

    private let subjectDetector = SubjectDetector()
    private let dateDetector = DateDetector()

    func extract(from extractedText: ExtractedText, fileURL: URL) -> DocumentMetadata {
        let normalizedText = extractedText.rawText.replacingOccurrences(of: "\r", with: "")
        let lines = normalizedText.split(separator: "\n").map { String($0) }
        let subject = subjectDetector.findSubject(in: lines)
        let date = dateDetector.findDate(in: normalizedText) ?? dateDetector.fallbackDate(for: fileURL)
        return DocumentMetadata(subject: subject, date: date, rawText: normalizedText)
    }
}

private final class SubjectDetector {
    func findSubject(in lines: [String]) -> String? {
        for line in lines {
            let lowercased = line.lowercased()
            if let marker = MetadataExtraction.subjectMarkers.first(where: { lowercased.contains($0) }) {
                let cleaned = line.replacingOccurrences(of: marker, with: "", options: .caseInsensitive)
                return sanitizedOrNil(from: cleaned)
            }
        }

        for line in lines.prefix(15) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard MetadataExtraction.allowedSubjectLength.contains(trimmed.count) else { continue }
            guard !isAddressLine(trimmed) else { continue }
            if let sanitized = sanitizedOrNil(from: trimmed) {
                return sanitized
            }
        }

        return nil
    }

    private func sanitizedOrNil(from value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        let components = trimmed.components(separatedBy: CharacterSet.whitespaces).filter { !$0.isEmpty }
        let joined = components.joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }

    private func isAddressLine(_ value: String) -> Bool {
        let lower = value.lowercased()
        return lower.contains("straße") || lower.contains("str.") || lower.contains("strasse") || lower.contains("plz")
    }
}

private final class DateDetector {
    private let strategies: [DateParsingStrategy] = [
        GermanNumericStrategy(),
        ISO8601Strategy(),
        LongFormStrategy()
    ]

    func findDate(in text: String) -> Date? {
        for strategy in strategies {
            if let date = strategy.firstDate(in: text) {
                return date
            }
        }
        return nil
    }

    func fallbackDate(for url: URL) -> Date? {
        let fileManager = FileManager.default
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return attributes?[.creationDate] as? Date
    }
}

private protocol DateParsingStrategy {
    func firstDate(in text: String) -> Date?
}

private struct GermanNumericStrategy: DateParsingStrategy {
    private static let regex = try! NSRegularExpression(
        pattern: "\\b(0?[1-9]|[12][0-9]|3[01])[.](0?[1-9]|1[0-2])[.](19|20)\\d\\d\\b"
    )

    func firstDate(in text: String) -> Date? {
        guard let match = Self.regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        let dateString = (text as NSString).substring(with: match.range)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.date(from: dateString)
    }
}

private struct ISO8601Strategy: DateParsingStrategy {
    private static let regex = try! NSRegularExpression(
        pattern: "\\b(19|20)\\d\\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])\\b"
    )

    func firstDate(in text: String) -> Date? {
        guard let match = Self.regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        let dateString = (text as NSString).substring(with: match.range)
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

private struct LongFormStrategy: DateParsingStrategy {
    private static let regex = try! NSRegularExpression(
        pattern: "\\b(0?[1-9]|[12][0-9]|3[01])\\s+(Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember)\\s+(19|20)\\d\\d\\b",
        options: .caseInsensitive
    )

    func firstDate(in text: String) -> Date? {
        guard let match = Self.regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        let dateString = (text as NSString).substring(with: match.range)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter.date(from: dateString)
    }
}
