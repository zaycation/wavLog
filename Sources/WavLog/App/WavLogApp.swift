import SwiftUI

@main
struct WavLogApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 700)
        #endif
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
}
