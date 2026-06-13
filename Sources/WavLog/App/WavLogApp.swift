import SwiftUI

@main
struct WavLogApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .task { await appState.restoreSession() }
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
    @Published var isRestoringSession = true
    @Published var onboardingComplete = false
    @Published var isKnownUser = false  // stored Apple user ID from prior sign-in

    enum AuthRoute: Equatable {
        case splash
        case inviteGate  // brand new — must pass invite gate first
        case signIn      // returning — SIWA directly, no invite gate
        case onboarding  // authenticated, profile not yet set up
        case app
    }

    var authRoute: AuthRoute {
        if isRestoringSession { return .splash }
        if isAuthenticated { return onboardingComplete ? .app : .onboarding }
        return isKnownUser ? .signIn : .inviteGate
    }

    var needsOnboarding: Bool { authRoute == .onboarding }

    func restoreSession() async {
        defer { isRestoringSession = false }
        isKnownUser = AuthService.shared.hasStoredAppleUser
        guard let profile = try? await AuthService.shared.restoreSession() else { return }
        currentUser = profile
        isAuthenticated = true
        onboardingComplete = profile.onboardingComplete
    }

    func signOut() async {
        try? await AuthService.shared.signOut()
        AuthService.shared.clearStoredAppleUser()
        currentUser = nil
        isAuthenticated = false
        onboardingComplete = false
        isKnownUser = false
    }
}
