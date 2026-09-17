import Foundation

enum Endpoint {
    case products(limit: Int, skip: Int, sortBy: String?, order: String?)
    case search(query: String, limit: Int, skip: Int, sortBy: String?, order: String?)
    case category(name: String, limit: Int, skip: Int, sortBy: String?, order: String?)
    case categories

    private static let baseURL = URL(string: "https://dummyjson.com")!

    var url: URL? {
        var components: URLComponents
        var queryItems: [URLQueryItem] = []

        switch self {
        case .products(let limit, let skip, let sortBy, let order):
            components = URLComponents(url: Self.baseURL.appendingPathComponent("products"), resolvingAgainstBaseURL: false)!
            queryItems += Self.paginationItems(limit: limit, skip: skip, sortBy: sortBy, order: order)

        case .search(let query, let limit, let skip, let sortBy, let order):
            components = URLComponents(url: Self.baseURL.appendingPathComponent("products/search"), resolvingAgainstBaseURL: false)!
            queryItems.append(URLQueryItem(name: "q", value: query))
            queryItems += Self.paginationItems(limit: limit, skip: skip, sortBy: sortBy, order: order)

        case .category(let name, let limit, let skip, let sortBy, let order):
            let path = "products/category/\(name)"
            components = URLComponents(url: Self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
            queryItems += Self.paginationItems(limit: limit, skip: skip, sortBy: sortBy, order: order)

        case .categories:
            components = URLComponents(url: Self.baseURL.appendingPathComponent("products/categories"), resolvingAgainstBaseURL: false)!
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
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
