import SwiftUI

@main
struct TripStoreApp: App {
    @State private var dependencies = AppDependencies()

    init() {
        URLCache.shared = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            Text("TripStore")
                .font(.largeTitle)
        }
    }
}
