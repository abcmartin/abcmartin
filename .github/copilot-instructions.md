# GitHub Copilot Instructions for AutoPDFRenamer

This file provides guidance for AI coding agents working on the AutoPDFRenamer codebase.

## Project Overview

AutoPDFRenamer is a macOS SwiftUI application that automatically renames PDF documents based on extracted metadata. It monitors a folder for incoming PDFs, extracts subject and date information using text analysis and OCR, and renames files to a normalized `YYYY-MM-DD_Subject.pdf` pattern.

## Architecture

### High-Level Structure

The application follows a service-oriented architecture with clear separation of concerns:

- **SwiftUI Views**: User interface (`ContentView.swift`)
- **ViewModels**: View state management (`ProcessingLogViewModel.swift`)
- **Services**: Business logic (folder watching, text extraction, metadata parsing, file renaming)
- **Models**: Data structures (`DocumentMetadata`, `ProcessingOutcome`, `LogEntry`)

### Key Components

1. **FolderWatcher** (`Services/FolderWatcher.swift`)
   - Uses macOS FSEvents API to monitor filesystem changes
   - Detects new or modified PDF files in real-time
   - Filters out already-processed files and files in Review subfolder

2. **ProcessingCoordinator** (`Services/ProcessingCoordinator.swift`)
   - Orchestrates the entire processing pipeline
   - Manages the processing queue and folder watcher
   - Coordinates between text acquisition, metadata extraction, and renaming services

3. **TextAcquisition** (`Services/TextAcquisition.swift`)
   - Extracts text from PDF documents
   - Prefers embedded PDF text, falls back to Vision OCR for scanned documents
   - Requires PDFKit and Vision frameworks (macOS-only)

4. **MetadataExtraction** (`Services/MetadataExtraction.swift`)
   - Parses extracted text to find document subject and date
   - Uses pattern matching for German document formats (can be extended for other locales)
   - Implements fallback strategies for incomplete metadata

5. **RenamingService** (`Services/RenamingService.swift`)
   - Applies the normalized filename pattern
   - Handles collision detection with automatic numbering
   - Moves files with insufficient metadata to Review subfolder

6. **ProcessingQueue** (`Services/ProcessingQueue.swift`)
   - Serializes file processing to prevent race conditions
   - Tracks pending operations to avoid duplicate processing

## Developer Workflows

### Opening and Building

1. **Requirements**: 
   - macOS 13.0 or later
   - Xcode 15 or later
   - Swift 5.9+

2. **Opening the Project**:
   ```bash
   # Open in Xcode
   open Package.swift
   # Or open the folder directly in Xcode
   ```

3. **Building and Running**:
   - In Xcode: Select the AutoPDFRenamer scheme and click Run (⌘R)
   - Command line: `swift build` (note: running requires macOS frameworks)

4. **Testing**:
   - In Xcode: Product → Test (⌘U)
   - Command line: `swift test` (limited on non-macOS platforms)

### Making Changes

When modifying code:
- Run tests after changes: `swift test` or ⌘U in Xcode
- The app must be built on macOS due to SwiftUI, AppKit, PDFKit, Vision, and CoreServices dependencies
- Tests focus on metadata extraction logic which is platform-independent

## Project Conventions

### Swift Style

- Use Swift's standard naming conventions (PascalCase for types, camelCase for variables/functions)
- Prefer `final class` for classes that won't be subclassed
- Use `private` access control for implementation details
- Favor protocol-oriented design for testability
- Use property wrappers appropriately (`@Published`, `@StateObject`, `@EnvironmentObject`)

### Code Organization

- **Services**: Business logic classes, protocol definitions
- **Models**: Data structures and enums
- **Views**: SwiftUI view components
- **ViewModels**: `@MainActor` classes that manage UI state with `@Published` properties

### File Naming

- Services: `[ServiceName]Service.swift` or `[ComponentName].swift`
- Views: `[ViewName]View.swift` or `ContentView.swift`
- ViewModels: `[Feature]ViewModel.swift`
- Models: `[ModelName].swift`

### Error Handling

- Custom error types conform to `LocalizedError` for user-friendly messages
- Use `throws` for recoverable errors
- Return enums like `ProcessingOutcome` for expected failure cases
- Avoid force unwrapping; prefer optional chaining or guard statements

### Date Handling

- Use `DateFormatter` with cached instances for performance
- Always specify `locale` for date parsing (typically `"en_US_POSIX"` for ISO dates, `"de_DE"` for German formats)
- Store dates as `Date` objects, format only for display/filenames

### String Manipulation

- Use `CharacterSet` for character filtering
- Regular expressions use `NSRegularExpression` (not string literals with regex syntax)
- Sanitize filenames by replacing unsafe characters with underscores

## Integration Points

### macOS Frameworks

1. **SwiftUI**: Modern declarative UI framework
   - Used for all UI components
   - Requires macOS 13.0+

2. **AppKit**: Traditional macOS UI framework
   - Used for file dialogs (`NSOpenPanel`)
   - Required by some SwiftUI functionality

3. **PDFKit**: PDF document manipulation
   - Used to extract embedded text from PDFs
   - Provides `PDFDocument` and `PDFPage` APIs

4. **Vision**: Apple's ML-based text recognition
   - Used for OCR on scanned PDFs
   - `VNRecognizeTextRequest` for text extraction

5. **CoreServices/FSEvents**: Filesystem monitoring
   - Low-level C API for efficient folder watching
   - Requires careful memory management with Unmanaged references

### External Dependencies

This project has **no external dependencies** beyond macOS system frameworks. All functionality is implemented using Apple's native APIs.

## Testing

### Test Structure

- Tests are located in `Tests/AutoPDFRenamerTests/`
- Focus on business logic (metadata extraction, date parsing, subject detection)
- UI testing is minimal as it requires full macOS environment

### Running Tests

```bash
swift test
```

Note: Tests that require SwiftUI, PDFKit, or Vision frameworks will only run on macOS.

### Writing Tests

- Inherit from `XCTestCase`
- Import the module with `@testable import AutoPDFRenamer`
- Use `XCTAssert*` methods for assertions
- Create temporary file URLs for file-based tests and clean up with `addTeardownBlock`

Example:
```swift
func testSubjectExtraction() throws {
    let text = ExtractedText(rawText: "Betreff: Test Subject", hasReliableText: true)
    let metadata = MetadataExtraction().extract(from: text, fileURL: temporaryFileURL())
    XCTAssertEqual(metadata.subject, "Test Subject")
}
```

## Common Tasks

### Adding a New Date Format

1. Create a new struct conforming to `DateParsingStrategy` in `MetadataExtraction.swift`
2. Implement `firstDate(in:)` with appropriate regex pattern
3. Add to the `strategies` array in `DateDetector`

### Adding a New Subject Pattern

1. Add the pattern to `subjectMarkers` array in `MetadataExtraction`
2. Or extend `SubjectDetector.findSubject(in:)` for complex logic

### Customizing the Renaming Pattern

Modify `RenamingService.apply(metadata:to:in:)` to change:
- Date format (currently `yyyy-MM-dd`)
- Filename structure (currently `DATE_SUBJECT`)
- Maximum filename length (currently 70 characters)

### Adding Localization

To support additional languages:
1. Add locale-specific patterns to `MetadataExtraction`
2. Update `DateDetector` strategies with locale-aware formatters
3. Extend `SubjectDetector.isAddressLine` with locale-specific keywords

## Debugging Tips

- FSEvents can be verbose; use breakpoints in `FolderWatcher.isRelevant(flag:url:)` to debug file detection
- For OCR issues, inspect `TextAcquisition.extractText` to see if text extraction succeeds
- For metadata extraction issues, examine the raw text in `DocumentMetadata.rawText`
- Use Xcode's Swift Package Index for symbol navigation
- The app logs are visible in the UI's "Recent Activity" section

## Performance Considerations

- Processing happens on a serial queue to prevent race conditions
- Date formatters are cached to avoid repeated initialization
- FSEvents provides efficient filesystem monitoring without polling
- OCR is expensive; the app prefers embedded PDF text when available

## Security & Privacy

- The app only accesses folders explicitly selected by the user
- No network access or external API calls
- All processing happens locally on the user's machine
- Temporary files should be created with unique names and cleaned up

## Future Enhancement Ideas

- Support for additional document types (images, Word documents)
- Multi-language support beyond German
- Configurable renaming patterns via UI
- Batch processing of existing files
- Document preview before renaming
- Integration with cloud storage services
- Support for custom metadata extraction rules via config files
