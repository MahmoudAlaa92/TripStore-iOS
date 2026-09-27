import Foundation
import Network

/// Reports connectivity *transitions* rather than point-in-time status, so
/// callers can react exactly when the network comes back instead of polling
/// or re-checking on every path update.
protocol NetworkMonitor {
    /// Yields once each time connectivity flips from unavailable to
    /// available. Never yields for the initial state or for repeated
    /// "still connected" updates, so a single subscriber can't be driven
    /// into a retry loop by the underlying path monitor's chatter.
    func connectivityRestored() -> AsyncStream<Void>
}

final class NWPathNetworkMonitor: NetworkMonitor {
    func connectivityRestored() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.tripstore.networkmonitor")
            var wasConnected: Bool?

            monitor.pathUpdateHandler = { path in
                let isConnected = path.status == .satisfied
                defer { wasConnected = isConnected }
                if isConnected, wasConnected == false {
                    continuation.yield(())
                }
            }
            continuation.onTermination = { _ in monitor.cancel() }
            monitor.start(queue: queue)
        }
    }
}
