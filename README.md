# TripStore

A travel-accessories catalogue app built as an iOS take-home assignment.

TripStore allows users to browse products, search and filter the catalogue, sort results, view product details, manage favourites, and create local booking-style orders using the DummyJSON Products API.

## Features

* Product catalogue with pagination
* Debounced product search
* Category and minimum-rating filters
* Price and rating sorting
* Pull-to-refresh
* Loading, empty, error, and retry states
* Product details with image gallery
* Stock-aware quantity selection
* Live order total calculation
* Favourites persisted locally
* Local order confirmation and order history
* Offline fallback for the cached first catalogue page
* Defensive API and persistence decoding
* Automated unit and integration-style tests

## Tech Stack

* **Swift 5.9+**
* **SwiftUI**
* **iOS 16+**
* **Xcode 16+**
* **Core Data**
* **URLSession**
* **Swift Concurrency (`async/await`)**
* **XcodeGen**

## Setup

### Requirements

* Xcode 16+
* iOS 16+ Simulator
* Homebrew
* XcodeGen

Install XcodeGen if it is not already installed:

```bash
brew install xcodegen
```

### Generate the Xcode project

The repository contains `project.yml` rather than a committed `.xcodeproj`. Generate the Xcode project with:

```bash
xcodegen generate
```

Then open the project:

```bash
open TripStore.xcodeproj
```

Select the `TripStore` scheme and an iOS 16+ simulator, then run with:

```text
⌘ + R
```

### Run tests

From Xcode:

```text
⌘ + U
```

Or from Terminal:

```bash
xcodebuild -project TripStore.xcodeproj \
  -scheme TripStore \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

If the selected simulator has a different name, replace `iPhone 17` with the installed simulator name.

## Architecture

The project follows **MVVM + Clean Architecture** with three main layers:

```text
Presentation  →  Domain  ←  Data
```

### Presentation

Contains SwiftUI views and `@MainActor` view models.

Responsibilities include:

* UI state
* User interactions
* Navigation
* Calling domain/repository interfaces
* Presenting loading, empty, error, and success states

Views are kept focused on presentation rather than business rules.

### Domain

Contains application business logic and abstractions:

* Entities
* Use cases
* Validation
* Pricing calculations
* Repository protocols

The Domain layer does not depend on SwiftUI, URLSession, or Core Data.

### Data

Contains implementations for external data sources and persistence:

* API client
* DTOs
* Network endpoints
* Catalogue cache
* Core Data stack
* Repository implementations

Remote API models are mapped to domain entities through DTO mapping, keeping API-specific details outside the Domain layer.

## Project Structure

```text
TripStore/
├── App/
│   ├── AppDependencies
│   ├── RootTabView
│   └── TripStoreApp
│
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   └── Repositories/
│
├── Data/
│   ├── DTO/
│   ├── Network/
│   ├── Cache/
│   ├── Persistence/
│   └── Repositories/
│
└── Presentation/
    ├── Catalogue/
    ├── Details/
    ├── Order/
    ├── Favorites/
    ├── OrderHistory/
    └── Shared/

TripStoreTests/
├── Domain/
├── Data/
├── Presentation/
└── Mocks/
```

## Dependency Injection

Dependencies are assembled in `AppDependencies` and injected into the relevant repositories and view models.

The application does not rely on a global service locator or singleton-based dependency graph.

This keeps production dependencies replaceable with mocks during testing.

`FavoritesStore` is shared through SwiftUI's environment because favourite state needs to remain consistent between catalogue, product details, and favourites screens.

## Networking

Networking is implemented using `URLSession` without a third-party networking framework.

The API client communicates with:

```text
https://dummyjson.com/products
```

Supported catalogue operations include:

* Product listing
* Product search
* Category filtering
* Category listing

Network failures are converted into application-level errors such as:

* Connectivity failure
* Timeout
* Invalid response
* Decoding failure
* Cancellation

DTOs use defensive decoding so malformed or missing API fields do not cause the application to crash.

## Concurrency

The application uses Swift Concurrency with `async/await`.

View models are isolated to the main actor for UI state updates.

Search requests use a **latest-query-wins** approach. Each reload receives a request identifier, and an outdated response is ignored if a newer request has already started.

Search input is also debounced to avoid sending a network request for every keystroke.

Order confirmation prevents duplicate submissions by guarding both the in-flight submission state and the already-confirmed state.

## Caching & Offline Behaviour

The cache intentionally focuses on the most useful baseline case:

**The last successful, unfiltered first catalogue page is cached locally.**

When the application cannot reach the API:

```text
Network request
      ↓
Connectivity failure
      ↓
Cached first page available?
      ├── Yes → Show cached data + stale/offline indicator
      └── No  → Show error + Retry
```

Search results, category-filtered results, and subsequent pages are not cached.

This keeps the cache implementation small and predictable while satisfying the required offline baseline.

Favourites and orders remain available offline because they are persisted locally using Core Data.

## Persistence

The project uses **Core Data** rather than SwiftData.

The minimum deployment target is iOS 16, while SwiftData requires iOS 17. Core Data therefore allows the project to keep the required iOS 16 deployment target.

Persistence is isolated behind repository protocols, so neither the Domain nor Presentation layers depend directly on Core Data.

The Core Data model is created programmatically and contains two main entities:

* `FavoriteEntity`
* `OrderEntity`

Tests use an in-memory Core Data store so they do not modify the application's persistent data.

## Order Flow

Orders are intentionally local-only.

The flow is:

```text
Product Details
      ↓
Select Quantity
      ↓
Order Confirmation
      ↓
Review:
- Product
- Quantity
- Subtotal
- Service Fee (5%)
- Final Total
      ↓
Confirm
      ↓
Save locally
      ↓
Order History
```

No real payment processing or backend order creation is implemented because it is outside the assignment scope.

## Assumptions

* Minimum deployment target: iOS 16.0
* Currency: USD
* Minimum-rating filtering is performed client-side
* Orders are local-only
* DummyJSON is treated as an external/untrusted data source
* The catalogue cache covers the last successful unfiltered first page
* Favourite and order persistence is fully local

## Testing

The project contains **43 automated tests** covering Domain, Data, and Presentation layers.

The test suite includes coverage for:

### Domain

* Price calculations
* Service fee calculation
* Two-decimal rounding
* Quantity validation
* Stock validation
* Rating filtering

### Data

* Repository behaviour
* Endpoint selection
* Mock network responses
* Cache save and fallback behaviour
* Core Data favourites
* Core Data orders
* Duplicate favourite handling
* Order persistence

### Presentation

* Loading state
* Success state
* Empty state
* Error state
* Filtering and sorting
* Reset behaviour
* Order confirmation
* Duplicate submission prevention
* Search concurrency
* Search debounce behaviour

Tests can be run with:

```text
⌘ + U
```

or using the `xcodebuild test` command described in the Setup section.

## Trade-offs & Known Limitations

### Catalogue cache

Only the first unfiltered catalogue page is cached.

A more advanced implementation could use a query-keyed cache with an LRU strategy for recent searches and filters.

### Image loading

The implementation relies on standard image loading and `URLCache`. A dedicated prefetching strategy could improve scrolling performance further on slow connections.

### Favourites

After toggling a favourite, the current implementation reloads the favourites collection. An incremental update could reduce the extra persistence round-trip for larger datasets.

### Refresh behaviour

Favourites and order history refresh when their screens appear rather than exposing pull-to-refresh, since they are local-only data owned by the application.

### Concurrency checking

The project uses Swift Concurrency and main-actor isolation, while a future iteration could enable stricter Swift 6 concurrency checking throughout the project.

## What I Would Improve Next

With additional development time, I would consider:

1. Query-aware offline caching
2. Image prefetching
3. More granular local state updates for favourites
4. UI tests for the main catalogue-to-order journey
5. Structured logging and request instrumentation
6. Additional accessibility validation
7. Stricter Swift 6 concurrency checking
8. Snapshot testing for important UI states

## AI Usage Disclosure

AI tools, including Claude Code, were used during the development process for implementation assistance, code generation, refactoring, test generation, and debugging.

The submitted project was reviewed against the assignment requirements, including the architecture, persistence approach, networking, concurrency behaviour, automated tests, and documented trade-offs.

The final submission remains the responsibility of the candidate, including understanding and verifying the submitted implementation.

## Submission Checklist

* [x] iOS 16+ deployment target
* [x] SwiftUI implementation
* [x] MVVM + Clean Architecture
* [x] Dependency injection
* [x] URLSession networking
* [x] Async/await concurrency
* [x] Search, filtering, and sorting
* [x] Pagination
* [x] Favourites persistence
* [x] Local order flow
* [x] Core Data persistence
* [x] Offline catalogue fallback
* [x] Automated tests
* [x] README documentation
* [x] No API keys or secrets required
