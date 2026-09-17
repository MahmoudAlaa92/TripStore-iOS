# TripStore

A travel-accessories catalogue app: browse, search, filter, sort, favourite,
and place local booking-style orders against the [dummyjson](https://dummyjson.com/products)
products API. Built as an iOS take-home submission.

## Setup

Requirements: Xcode 16+, iOS 17+ simulator, [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```bash
xcodegen generate
open TripStore.xcodeproj
```

The `.xcodeproj` is generated from [`project.yml`](project.yml) and is
gitignored — regenerate it any time the project structure changes. Run the
`TripStore` scheme on an iOS 17+ simulator; run tests with `Cmd+U` or:

```bash
xcodebuild -project TripStore.xcodeproj -scheme TripStore \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Architecture

MVVM + Clean Architecture, three layers, dependencies point inward:

```
Presentation  →  Domain  ←  Data
(SwiftUI Views,    (Entities,     (DTOs, URLSession,
 ViewModels)        Use Cases,     SwiftData,
                     Repository     Repository
                     protocols)     implementations)
```

- **Domain** has no dependency on SwiftUI, URLSession, or SwiftData — it's
  entities (`Product`, `Order`, ...), pure calculations (`PricingCalculator`,
  `QuantityValidator`, `ProductRatingFilter`), and repository *protocols*
  (`ProductsRepository`, `FavoritesRepository`, `OrdersRepository`,
  `CategoriesRepository`).
- **Data** implements those protocols: `DefaultProductsRepository` +
  `URLSessionAPIClient` for the network, `SwiftDataFavoritesRepository` /
  `SwiftDataOrdersRepository` for persistence. DTOs (`ProductDTO`, ...) are
  the only place remote JSON shape is known; everything past `toDomain()`
  deals only in domain entities.
- **Presentation** is SwiftUI views + `@MainActor` `ObservableObject`
  view models. Views hold no business logic — quantity clamping, pricing,
  and duplicate-order prevention all live in the Domain layer or the view
  model, never inline in a `View`.

### Folder structure

```
TripStore/
  App/            Composition root (AppDependencies), RootTabView, entry point
  Domain/
    Entities/     Product, Order, CataloguePage, CatalogueQuery, AppError, ...
    UseCases/     PricingCalculator, QuantityValidator, ProductRatingFilter, ...
    Repositories/ Protocols only
  Data/
    DTO/          Defensive-decoding wire types + toDomain() mapping
    Network/      Endpoint, APIClient protocol, URLSessionAPIClient
    Cache/        FileCatalogueCache (offline baseline)
    Persistence/  SwiftData @Model types (FavoriteRecord, OrderRecord)
    Repositories/ Concrete repository implementations
  Presentation/
    Catalogue/ Details/ Order/ Favorites/ OrderHistory/   one screen each
    Shared/    Reusable components (ProductCard, RatingView, QuantitySelector, ...)
TripStoreTests/
  Domain/ Data/ Presentation/   mirrors the app's structure
  Mocks/                        MockAPIClient, MockProductsRepository, ...
```

### Dependency injection

`AppDependencies` (`App/AppDependencies.swift`) is a plain constructor-
injection container built once in `TripStoreApp.init`. It owns the
`URLSessionAPIClient`, the `ModelContainer`, and every repository, and
hands out concrete types *behind their protocol*. Views/view models never
reach into a singleton — everything is passed through initializers
(`CatalogueViewModel(repository:categoriesRepository:)`,
`ProductDetailsView(product:)`, ...), so tests substitute mocks without
touching this container at all. `FavoritesStore` is the one shared
instance (via `.environmentObject`) because favourite state must be
consistent across the Catalogue, Details, and Favorites screens by
construction, not by convention.

### Networking

`URLSession` only — no third-party networking library. `Endpoint` builds
requests against `https://dummyjson.com` (`/products`, `/products/search`,
`/products/category/{name}`, `/products/categories`); `URLSessionAPIClient`
is the only type that touches `URLSession` and maps every failure mode
(no connection, timeout, non-2xx status, decoding, cancellation) into the
`AppError` taxonomy so nothing above the Data layer ever sees a raw
`URLError`/`DecodingError`. DTOs decode every field defensively
(`decodeIfPresent` + safe fallbacks) — a missing or malformed field from
the API degrades to a sane default (`"Untitled product"`, price 0,
skipped image URL, ...) instead of crashing the decode.

### Concurrency

Swift concurrency (`async`/`await`) throughout; all view models are
`@MainActor`, all SwiftData repositories are `@ModelActor` actors so
persistence work stays off the main actor.

**Search/filter latest-query-wins**: `CatalogueViewModel` stamps every
`reload()` with a fresh request ID before awaiting the network call. When
the response comes back, it's discarded unless that ID is still the
current one — so a slower, *earlier* request can never overwrite a
faster, *later* one, regardless of network timing. The same guard covers
pagination and pull-to-refresh. Typing is separately debounced (300ms,
cancelling the previous timer) so rapid keystrokes never fire one request
per character — see `CatalogueViewModelConcurrencyTests` for both a
timing-independent test of the request-ID guard and a debounce-collapse
test.

**Duplicate order prevention**: `OrderConfirmationViewModel.confirm()` is
guarded by `isSubmitting` (blocks a second tap while the first is still
in flight — checked synchronously before the first `await`, so two
near-simultaneous taps can't both pass the guard) and `isConfirmed`
(blocks any further attempt once an order exists). Covered by both a
sequential and a concurrent (`async let`) test.

### Cache strategy

Only the **plain, unfiltered, first page** of the catalogue is cached
(`FileCatalogueCache`, one JSON file in the caches directory, overwritten
on every successful fetch of that exact shape). Deliberately simple, per
the challenge's own guidance against building TTL/stale-while-revalidate
machinery before the mandatory requirements are done:

- On a connectivity failure *for that plain first page*, the repository
  returns the cached page marked `isStale`, and the catalogue shows it
  with an offline banner instead of a blocking error.
- Search results, category filters, and pages beyond the first are never
  cached — offline, those fall through to the error+retry state. This is
  a conscious trade-off documented here rather than a bug: caching every
  possible query/page combination would add real complexity for a
  take-home-scale benefit.
- Favourites and orders need no such cache — SwiftData is local by
  construction, so they work fully offline already.

### Persistence

SwiftData, chosen because it's mandated and the project targets iOS 17+.
`FavoriteRecord` and `OrderRecord` share one `ModelContainer` (built once
in `AppDependencies`); `SwiftDataFavoritesRepository` and
`SwiftDataOrdersRepository` are `@ModelActor` actors wrapping it, so nothing
in Presentation or Domain ever imports `SwiftData` — persistence is fully
behind the `FavoritesRepository`/`OrdersRepository` protocol boundary. Both
`toDomain()` mappers clamp out-of-range values (negative price, NaN,
empty title) instead of crashing, so a corrupted record can't take the
app down.

## Assumptions

- **iOS 17.0 minimum**, not 16 as the challenge text says. SwiftData is
  explicitly mandated and only exists from iOS 17 — this was the one
  unavoidable deviation, made rather than stopping to ask, and called out
  here per the challenge's own "state assumptions" guidance.
- Minimum-rating filtering is client-side only (dummyjson has no
  server-side support for it); with a rating filter active, the `total`
  shown still reflects the server's unfiltered count. See the Cache
  strategy trade-off above for the analogous search/category-pagination
  scope decision.
- Currency is fixed to USD (dummyjson prices are USD; no locale switch
  was in scope).
- Orders are local-only "booking-style" records, never sent to a backend
  — this is explicit in the challenge (no backend order creation).

## Known limitations / what I'd improve with more time

- Offline cache covers only the plain first page (see above) — a
  keyed-by-query cache (LRU over recent `CatalogueQuery` values) would
  extend offline support to recent searches/filters.
- No image pre-fetching/pre-caching beyond `URLCache` sizing at launch;
  a dedicated prefetch-on-scroll pass would smooth out fast scrolling on
  a slow connection.
- `FavoritesStore.toggle` re-fetches the entire favourites list after an
  add (simplest correct implementation); an incremental local update
  would avoid the extra SwiftData round-trip for large favourite lists.
- No pull-to-refresh on Favorites/Orders (both refresh on tab appear
  instead, which is sufficient for local-only data that only this app
  writes to).
- Strict (Swift 6 mode) concurrency checking was left off — the project
  builds warning-free under Swift 5.9's default checking, but a full
  Swift 6 migration would be the next step for maximum compile-time
  data-race safety.

## Testing

35 tests across `TripStoreTests/Domain`, `Data`, and `Presentation`.
Run with `Cmd+U` in Xcode or the `xcodebuild test` command above.
Highlights:

- **Domain**: pricing (subtotal/fee/total, 2-decimal rounding including
  the classic `0.1 + 0.2` case), quantity validation (bounds, stock 0),
  rating filter.
- **Data**: `DefaultProductsRepository` against a mock `APIClient` —
  endpoint selection per query shape, cache save/fallback/rethrow.
- **Presentation**: catalogue load success/empty/error/loading states,
  filter/sort/reset behavior, order confirmation totals and duplicate
  prevention (sequential + concurrent), and the two concurrency
  guarantees called out above (obsolete-response guard, debounce
  collapse).

## AI usage disclosure

This project was built with **Claude Code** (Anthropic), operating
largely autonomously against a detailed phased specification covering
architecture, UI, concurrency, testing, and delivery requirements. Claude
Code:

- Wrote all production and test source files, `project.yml`, and this
  README.
- Ran `xcodegen generate` and `xcodebuild` (build + test) after every
  phase, fixing failures before committing.
- Drove the app in the iOS Simulator (screenshots + taps) to visually
  verify the catalogue, search/filters, product details, favourites,
  order confirmation, and order history flows, and to catch a real bug
  this way: a favourite button nested inside a `NavigationLink`'s label
  was triggering both the favourite toggle *and* navigation on one tap
  (see the `fix(catalogue):` commit) — found by exercising the app, not
  by reading the code.
- Made and documented the deployment-target deviation (17.0 vs the
  brief's 16+) and the cache/rating-filter scope trade-offs above, rather
  than silently working around them.

**What to verify before submitting**: every line was generated by AI.
Per the challenge's own instructions, review the commit history (`git
log`) and diffs before treating this as your own submission — in
particular the concurrency guards (`CatalogueViewModel.reload()`'s
request-ID check, `OrderConfirmationViewModel.confirm()`'s double guard),
the SwiftData `@ModelActor` repositories, and the cache trade-offs
documented above, since those are the areas most likely to need judgment
calls a human reviewer would want to double-check.
