import SwiftUI

@main
struct TricksPlannerApp: App {
    @StateObject private var store = TrickStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
