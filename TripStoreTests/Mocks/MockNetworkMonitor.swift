import Foundation
@testable import TripStore

/// Lets a test fire a connectivity-restored event on demand via
/// `simulateConnectivityRestored()`, instead of depending on real
/// `NWPathMonitor` state.
final class MockNetworkMonitor: NetworkMonitor {
    private var continuation: AsyncStream<Void>.Continuation?

    func connectivityRestored() -> AsyncStream<Void> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func simulateConnectivityRestored() {
        continuation?.yield(())
    }
}
