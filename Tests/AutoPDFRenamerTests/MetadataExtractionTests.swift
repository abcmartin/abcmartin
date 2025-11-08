import Foundation
import XCTest
@testable import AutoPDFRenamer

final class MetadataExtractionTests: XCTestCase {
    func testSubjectWithExplicitMarker() throws {
        let text = ExtractedText(
            rawText: "Absender\nBetreff: Leistungsabrechnung\nSehr geehrte Damen und Herren",
            hasReliableText: true
        )
        let metadata = MetadataExtraction().extract(from: text, fileURL: temporaryFileURL())
        XCTAssertEqual(metadata.subject, "Leistungsabrechnung")
    }

    func testSubjectFallbackFromHeader() throws {
        let text = ExtractedText(
            rawText: "Krankenhaus Musterstadt\nLeistungsabrechnung Quartal 3\nSehr geehrte Damen und Herren",
            hasReliableText: true
        )
        let metadata = MetadataExtraction().extract(from: text, fileURL: temporaryFileURL())
        XCTAssertEqual(metadata.subject, "Leistungsabrechnung Quartal 3")
    }

    func testGermanDateDetection() throws {
        let text = ExtractedText(
            rawText: "Leistungsabrechnung\n01.12.2024\nVielen Dank",
            hasReliableText: true
        )
        let metadata = MetadataExtraction().extract(from: text, fileURL: temporaryFileURL())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        XCTAssertEqual(formatter.string(from: metadata.date!), "2024-12-01")
    }

    private func temporaryFileURL() -> URL {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let url = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        FileManager.default.createFile(atPath: url.path, contents: Data())
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }
}
