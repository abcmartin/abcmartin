import SwiftUI

@main
struct AutoPDFRenamerApp: App {
    @StateObject private var viewModel = ProcessingLogViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .commands {
            CommandMenu("Processing") {
                Button("Select Input Folder") {
                    viewModel.promptForFolderSelection()
                }
            }
        }
    }
}
