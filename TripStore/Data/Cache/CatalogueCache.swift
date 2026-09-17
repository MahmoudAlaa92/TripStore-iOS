import Foundation

protocol CatalogueCache {
    func save(_ page: CataloguePage)
    func load() -> CataloguePage?
}

/// Persists a single JSON snapshot of the plain (unfiltered, unsearched)
/// first catalogue page to disk. Deliberately simple: one file, overwritten
/// on every successful default-catalogue fetch, no TTL or invalidation
/// beyond "the newest successful fetch always wins" — see README's cache
/// strategy section for the rationale.
final class FileCatalogueCache: CatalogueCache {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.tripstore.cataloguecache")

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        fileURL = directory.appendingPathComponent("catalogue_cache.json")
    }

    func save(_ page: CataloguePage) {
        let snapshot = CachedCataloguePage(page: page)
        queue.async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: self.fileURL, options: .atomic)
        }
    }

    func load() -> CataloguePage? {
        queue.sync {
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            guard let snapshot = try? JSONDecoder().decode(CachedCataloguePage.self, from: data) else { return nil }
            return snapshot.toDomain(isStale: true)
        }
    }
}
