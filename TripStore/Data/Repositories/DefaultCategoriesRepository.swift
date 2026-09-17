import Foundation

final class DefaultCategoriesRepository: CategoriesRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchCategories() async throws -> [String] {
        let data = try await apiClient.data(for: .categories)
        return CategoriesResponseDecoder.decode(data)
    }
}
