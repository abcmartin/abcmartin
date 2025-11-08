# AutoPDFRenamer

A macOS SwiftUI application that watches an inbox folder for newly arrived PDF documents, extracts subject and date metadata via OCR/Text analysis, and automatically renames each file to the normalized pattern `YYYY-MM-DD_Subject.pdf`. Files with insufficient metadata are moved into a `Review/` subfolder for manual handling.

## Features

- Folder watcher built on top of `FSEvents` to react to incoming or modified PDFs in near real time.
- Text extraction pipeline that prefers embedded PDF text and falls back to Vision OCR for image-only scans.
- Heuristics tailored to German correspondence for subject and date extraction, including multiple date formats and fallback to file metadata.
- Collision-safe renaming with sanitation of unsafe characters and a review flow for ambiguous documents.
- SwiftUI interface with a processing log and quick access to the monitored folder selection.

## Project Structure

- `Sources/AutoPDFRenamer/` – SwiftUI app, services for watching folders, OCR, metadata extraction, and renaming.
- `Tests/AutoPDFRenamerTests/` – Unit tests covering the metadata extraction heuristics.
- `Package.swift` – Swift package definition targeting macOS 13 and higher.

## Getting Started

1. Open the project in Xcode 15 or later (`File` → `Open` → select the repository folder).
2. Select the **AutoPDFRenamer** scheme and run the app.
3. Choose the inbox folder to monitor via the **Processing → Select Input Folder** menu command or the button in the main view.

## Testing

Run unit tests from Xcode (**Product → Test**) or via the command line:

```bash
swift test
```

> **Note:** OCR and PDF processing require running on macOS with access to the Vision and PDFKit frameworks. Tests provided focus on deterministic metadata extraction logic and run without those frameworks.
