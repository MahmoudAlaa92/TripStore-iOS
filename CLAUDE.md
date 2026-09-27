# TripStore — Claude Code Project Instructions

## Project Context

TripStore is a production-minded iOS take-home challenge for a Strong Junior iOS Developer role.

The goal is a small, complete, well-tested application. Prioritize correctness, engineering judgment, clarity, resilience, and maintainability over adding unnecessary features.

## Platform & Technology Constraints

- iOS 16+
- Swift 5.9+
- SwiftUI is preferred
- Use Apple frameworks and Swift Package Manager
- Networking must use URLSession
- Use Swift Concurrency (async/await)
- Do not add third-party networking libraries
- Persistence may use SwiftData, Core Data, or a justified lightweight solution
- Do not store sensitive information in UserDefaults
- External image-loading/cache packages are allowed only when clearly justified
- Never add dependencies without a clear reason

IMPORTANT:
- Do not raise the deployment target above iOS 16 unless explicitly requested.
- Do not introduce Swift 6/iOS 17-only APIs when an iOS 16-compatible solution is required.
- Before using an API, verify that it is available on the project's deployment target.

## Architecture

Follow the architecture already established in the project.

Keep clear separation between:

- Presentation / UI
- Domain / business logic
- Data access
- Networking
- Persistence

Use dependency injection so production services can be replaced with test doubles.

Avoid:

- Massive Views
- Massive ViewModels
- "Manager" classes with unrelated responsibilities
- Business logic inside SwiftUI Views
- Tight coupling between UI and networking/persistence
- Unnecessary refactoring

Prefer small, focused, testable types and clear protocols where they provide real value.

## Existing Project Structure

Respect the existing project organization:

- App
- Data
- Domain
- Presentation
- Resources
- TripStoreTests

Do not reorganize the project structure unless there is a concrete architectural reason and the change is approved.

## Product Requirements

TripStore is a travel-accessories catalogue using the DummyJSON Products API.

Required flows:

1. Catalogue
   - Load products
   - Show image, title, category, rating, and price
   - Support pagination or incremental loading
   - Pull-to-refresh
   - Distinct loading, empty, and error states
   - Retry after failure

2. Search / Sort / Filter
   - Debounced search
   - Cancel or ignore obsolete search work
   - Category filter
   - Minimum-rating filter
   - Sort by price ascending/descending
   - Sort by rating
   - Combined state must produce the visible result
   - Clear/reset action

3. Product Details
   - Relevant product details
   - Image gallery
   - Favourite toggle
   - Quantity from 1 to available stock
   - Live total rounded to 2 decimal places
   - Prevent invalid quantity and out-of-stock ordering

4. Favourites
   - Persist across launches
   - Consistent across catalogue, details, and favourites
   - Removing a favourite updates visible screens correctly
   - Must work offline

5. Local Order Flow
   - Confirmation screen
   - Product
   - Quantity
   - Subtotal
   - Service fee = 5%
   - Final total
   - Explicit confirmation
   - Prevent double submission
   - Persist confirmed orders locally
   - Order history
   - Unique order ID and timestamp

## Networking & Concurrency

Use URLSession and async/await.

Model errors meaningfully, including:

- Connectivity
- Timeout
- Invalid response / HTTP status
- Decoding
- Cancellation

Search requirements:

- Debounce rapid typing
- Latest query wins
- Cancel or ignore obsolete requests
- An old response must never overwrite a newer query

UI-related state updates must be performed safely on the main actor.

Do not silently swallow errors.

## Caching & Offline Behaviour

Cache the last successful catalogue response.

When offline:

- Show cached catalogue if available
- Clearly communicate that cached data may be stale
- Favourites remain available
- Orders remain available

When offline with no cache:

- Show an actionable error
- Provide Retry

Keep cache logic isolated and testable.

Document cache strategy and invalidation decisions in README.

## Persistence

Persistence code must be isolated behind a protocol or repository boundary.

Handle:

- Corrupt records
- Partial records
- Missing optional data

The app must not crash because of malformed persisted data.

## API & Defensive Decoding

Remote API data is untrusted.

Handle malformed or missing optional fields safely.

Use sensible UI fallbacks instead of force-unwrapping remote data.

Avoid force unwraps in production paths unless the invariant is explicitly justified.

## Accessibility & UX

Support:

- Dynamic Type
- Meaningful VoiceOver labels for primary controls/content
- Responsive scrolling
- Clear loading/empty/error/offline states
- Clear validation feedback

Prefer simple, understandable UX over unnecessary visual complexity.

## Testing Requirements

Maintain meaningful automated tests.

At minimum cover:

- Price calculation
- Rounding
- 5% service fee
- Quantity validation
- Search/filter/sort behaviour
- ViewModel/presentation success state
- Loading state
- Empty state
- Error state
- At least one repository test using a mock network service
- Obsolete search response cannot replace the latest result

Minimum expectation: at least 8 meaningful automated tests.

When changing business logic, repositories, ViewModels, or concurrency behaviour, add/update the relevant tests.

## Build & Validation Workflow

After meaningful implementation changes:

1. Build the project.
2. Run relevant automated tests.
3. Fix compiler errors and test failures.
4. Check for warnings.
5. Inspect the Git diff.
6. Verify that no unrelated files were changed.

Never claim a feature is complete without validating it when the required tools are available.

## Git Rules

Do not commit unless explicitly requested.

Never:

- Force push
- Rewrite Git history
- Delete commits
- Reset or discard user changes
- Modify unrelated changes

unless the user explicitly asks for it.

Use meaningful incremental commits.

Prefer Conventional Commit style when creating commits, for example:

- feat: add product filtering
- fix: prevent duplicate order submission
- test: add repository pagination tests
- refactor: isolate persistence repository

Before committing, inspect:

- git status
- git diff
- changed files

Never include secrets, generated build folders, personal data, or unrelated files.

## Code Change Rules

Before implementing a non-trivial feature:

1. Explore the relevant existing code.
2. Identify the current architecture and dependencies.
3. Propose a concise implementation plan.
4. Identify affected files.
5. Wait for approval when the change is architectural, broad, risky, or ambiguous.

For small, clearly scoped changes, implementation may proceed directly.

When implementing:

- Reuse existing abstractions and components.
- Keep changes minimal.
- Do not refactor unrelated code.
- Match existing naming and coding style.
- Avoid speculative abstractions.
- Do not introduce a dependency just to solve a small problem.

## AI-Assisted Development

AI tools are permitted for this challenge, but their use must be disclosed in README.

Claude must help with implementation while the developer remains responsible for every submitted line.

Do not claim work was manually written if it was AI-assisted.

When requested, help maintain an accurate README section describing:

- Where AI assistance was used
- What Claude generated or modified
- What was personally reviewed and verified

## Important Challenge Priorities

Mandatory requirements come before optional senior-level extensions.

Do not add optional features until mandatory functionality is correct, stable, tested, and documented.

Prefer:

Complete + correct + tested

over:

Many features + unfinished edge cases

## How Claude Should Work

For complex requests, follow this workflow:

1. EXPLORE
   - Inspect only the relevant files and dependencies.
   - Do not read the entire repository unnecessarily.

2. PLAN
   - Explain the proposed approach.
   - Identify files to create/modify.
   - Identify edge cases and testing needs.

3. IMPLEMENT
   - Make the smallest appropriate changes.
   - Follow the existing architecture.

4. VALIDATE
   - Build.
   - Run relevant tests.
   - Check warnings/errors.

5. REVIEW
   - Inspect the diff.
   - Look for concurrency issues, state bugs, unnecessary complexity, and missing tests.

6. REPORT
   - Summarize what changed.
   - Mention tests/build results.
   - Mention any remaining risks or assumptions.

## Context & Token Efficiency

Be efficient with context.

Do not read the entire repository when the task is localized.

Start from the feature or error mentioned by the user and follow dependencies only as needed.

Prefer targeted exploration over broad repository dumps.

Do not repeat information already available in this file.

When a task is ambiguous, ask a focused question instead of making a large speculative change.

## Safety

Before destructive operations, ask for explicit confirmation.

Treat user changes as protected.

Never overwrite or discard existing work without confirmation.

