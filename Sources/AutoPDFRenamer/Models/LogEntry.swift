import Foundation

struct LogEntry: Identifiable {
    let id = UUID()
    let title: String
    let details: String
}
