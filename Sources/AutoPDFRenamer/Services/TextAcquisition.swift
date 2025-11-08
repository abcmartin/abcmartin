import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(Vision)
import Vision
#endif

struct TextAcquisitionError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

final class TextAcquisition {
    func extractText(from url: URL) throws -> ExtractedText {
        #if canImport(PDFKit)
        guard let document = PDFDocument(url: url) else {
            throw TextAcquisitionError(message: "Unable to open PDF")
        }

        var accumulated = ""
        for index in 0..<document.pageCount {
            if let page = document.page(at: index), let pageText = page.string, !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                accumulated.append(pageText)
                accumulated.append("\n")
            }
        }

        if !accumulated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ExtractedText(rawText: accumulated, hasReliableText: true)
        }

        guard let firstPage = document.page(at: 0) else {
            throw TextAcquisitionError(message: "Empty PDF document")
        }

        let pageBounds = firstPage.bounds(for: .mediaBox)
        let imageSize = NSSize(width: pageBounds.width, height: pageBounds.height)
        let image = firstPage.thumbnail(of: imageSize, for: .mediaBox)
        return try performOCR(on: image)
        #else
        throw TextAcquisitionError(message: "PDFKit not available")
        #endif
    }

    private func performOCR(on image: NSImage) throws -> ExtractedText {
        #if canImport(Vision)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw TextAcquisitionError(message: "Unable to obtain CGImage")
        }

        var requestError: Error?
        var recognizedText = ""
        let request = VNRecognizeTextRequest { request, error in
            if let error {
                requestError = error
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        }

        request.recognitionLanguages = ["de-DE", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        if let error = requestError {
            throw error
        }

        return ExtractedText(rawText: recognizedText, hasReliableText: false)
        #else
        throw TextAcquisitionError(message: "Vision not available")
        #endif
    }
}

struct ExtractedText {
    let rawText: String
    let hasReliableText: Bool
}
