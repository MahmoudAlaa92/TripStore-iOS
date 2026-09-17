import Foundation

/// One page of catalogue results plus enough paging metadata for the
/// presentation layer to decide whether more pages remain.
struct CataloguePage: Equatable {
    let products: [Product]
    let total: Int
    let skip: Int
    let limit: Int
    /// True when this page was served from the local cache because the
    /// network request failed (offline / connectivity error).
    let isStale: Bool

    var hasMore: Bool { skip + products.count < total }

    static let empty = CataloguePage(products: [], total: 0, skip: 0, limit: 0, isStale: false)
}
