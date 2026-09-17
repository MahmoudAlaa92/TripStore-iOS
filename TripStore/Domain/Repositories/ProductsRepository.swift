import Foundation

protocol ProductsRepository {
    /// Fetches one page of the catalogue for the given query. On connectivity
    /// failure with a locally cached baseline available (no search/category/
    /// sort applied), returns that cache marked `isStale`. Search results and
    /// filtered/sorted pages are never cached — only the plain first page is.
    func fetchCatalogue(query: CatalogueQuery, limit: Int, skip: Int) async throws -> CataloguePage
}
