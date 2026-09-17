import Foundation

/// User-facing error taxonomy. Technical errors (URLError, DecodingError,
/// CancellationError, ...) are mapped into one of these at the data boundary
/// so presentation code never has to interpret raw system errors.
enum AppError: Error, Equatable {
    case connectivity
    case timeout
    case invalidResponse
    case decoding
    case cancelled
    case unknown

    var userMessage: String {
        switch self {
        case .connectivity:
            return "You're offline. Check your connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .invalidResponse:
            return "Something went wrong on our end. Please try again."
        case .decoding:
            return "We couldn't read the server's response. Please try again."
        case .cancelled:
            return "The request was cancelled."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
