import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ProcessingLogViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Monitored Folder") {
                HStack {
                    if let url = viewModel.selectedFolder {
                        Text(url.path)
                            .font(.caption)
                            .textSelection(.enabled)
                    } else {
                        Text("No folder selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Change…") {
                        viewModel.promptForFolderSelection()
                    }
                }
            }
            GroupBox("Recent Activity") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.logEntries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title)
                                    .font(.headline)
                                Text(entry.details)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                    .padding(4)
                }
                .frame(minHeight: 200)
            }
            Spacer()
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 400)
        .onAppear {
            viewModel.startIfNeeded()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProcessingLogViewModel())
}
