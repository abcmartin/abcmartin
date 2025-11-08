import Foundation

enum ProcessingOutcome {
    case renamed(newURL: URL)
    case movedToReview(reviewURL: URL)
    case failed(error: Error)
}
