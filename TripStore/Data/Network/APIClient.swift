import Foundation

protocol APIClient {
    func data(for endpoint: Endpoint) async throws -> Data
}

extension APIClient {
    /// Convenience decode helper shared by every repository — keeps
    /// `JSONDecoder` configuration in one place.
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await data(for: endpoint)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch is DecodingError {
            throw AppError.decoding
        }
    }
}
