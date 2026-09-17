import Foundation

/// dummyjson's `/products/categories` has returned either a plain array of
/// strings or an array of `{slug, name, url}` objects across API versions.
/// Decoding tries the object shape first and falls back to plain strings so
/// either shape works without crashing.
struct CategoryDTO: Decodable {
    let slug: String?
    let name: String?

    var displayName: String? {
        name?.isEmpty == false ? name : slug
    }
}

enum CategoriesResponseDecoder {
    static func decode(_ data: Data) -> [String] {
        if let objects = try? JSONDecoder().decode([CategoryDTO].self, from: data) {
            let names = objects.compactMap { $0.displayName }
            if !names.isEmpty { return names }
        }
        if let strings = try? JSONDecoder().decode([String].self, from: data) {
            return strings
        }
        return []
    }
}
