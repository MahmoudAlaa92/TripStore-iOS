import Foundation

/// The only place URLSession is touched. Maps every technical failure mode
/// (no connection, timeout, bad status code, cancellation) into `AppError`.
final class URLSessionAPIClient: APIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        guard let url = endpoint.url else {
            throw AppError.invalidResponse
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError.invalidResponse
            }
            return data
        } catch is CancellationError {
            throw AppError.cancelled
        } catch let error as AppError {
            throw error
        } catch let urlError as URLError {
            throw Self.map(urlError)
        } catch {
            throw AppError.unknown
        }
    }

    private static func map(_ error: URLError) -> AppError {
        switch error.code {
        case .cancelled:
            return .cancelled
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .connectivity
        default:
            return .unknown
        }
    }
}
