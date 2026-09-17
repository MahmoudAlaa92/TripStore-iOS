import Foundation

protocol CategoriesRepository {
    func fetchCategories() async throws -> [String]
}
