import Foundation

final class ProcessingQueue {
    private let serialQueue = DispatchQueue(label: "de.abcmartin.autopdfr.queue")
    private var pending: Set<URL> = []

    func enqueue(_ url: URL, handler: @escaping (URL) -> Void) {
        serialQueue.async { [weak self] in
            guard let self else { return }
            guard !self.pending.contains(url) else { return }
            self.pending.insert(url)
            handler(url)
            self.pending.remove(url)
        }
    }
}
