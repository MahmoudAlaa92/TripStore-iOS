import Foundation

enum Endpoint {
    case products(limit: Int, skip: Int, sortBy: String?, order: String?)
    case search(query: String, limit: Int, skip: Int, sortBy: String?, order: String?)
    case category(name: String, limit: Int, skip: Int, sortBy: String?, order: String?)
    case categories

    // A hardcoded, well-formed constant string can only fail URL(string:)
    // if it were mistyped — a compile-time invariant, not a runtime risk.
    private static let baseURL = URL(string: "https://dummyjson.com")!

    var url: URL? {
        guard var components = URLComponents(url: Self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            return nil
        }
        let queryItems = self.queryItems
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }

    private var path: String {
        switch self {
        case .products:
            return "products"
        case .search:
            return "products/search"
        case .category(let name, _, _, _, _):
            return "products/category/\(name)"
        case .categories:
            return "products/categories"
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case .products(let limit, let skip, let sortBy, let order):
            return Self.paginationItems(limit: limit, skip: skip, sortBy: sortBy, order: order)

        case .search(let query, let limit, let skip, let sortBy, let order):
            return [URLQueryItem(name: "q", value: query)]
                + Self.paginationItems(limit: limit, skip: skip, sortBy: sortBy, order: order)

        case .category(_, let limit, let skip, let sortBy, let order):
            return Self.paginationItems(limit: limit, skip: skip, sortBy: sortBy, order: order)

        case .categories:
            return []
        }
    }

    private static func paginationItems(limit: Int, skip: Int, sortBy: String?, order: String?) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "skip", value: String(skip))
        ]
        if let sortBy { items.append(URLQueryItem(name: "sortBy", value: sortBy)) }
        if let order { items.append(URLQueryItem(name: "order", value: order)) }
        return items
    }
}
