import SwiftUI

// Shown to returning users whose Apple ID we've seen before.
// No invite gate — straight to SIWA.
struct SignInView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                AnimatedWaveformView()
                    .frame(height: 160)
                    .padding(.horizontal, 8)

                Spacer().frame(height: 48)

                VStack(spacing: 6) {
                    Text("WavLog")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryText)
                    Text("Your music project journal")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                }

                Spacer()

                VStack(spacing: 14) {
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    SignInWithAppleSection(validatedCode: nil) { profile in
                        appState.currentUser = profile
                        appState.onboardingComplete = profile.onboardingComplete
                        appState.isAuthenticated = true
                    } onError: { message in
                        errorMessage = message
                    }

                    #if DEBUG
                    Button("Skip (Dev Only)") {
                        appState.isAuthenticated = true
                        appState.onboardingComplete = true
                        appState.currentUser = UserProfile(
                            id: "dev-user",
                            displayName: "Dev User",
                            avatarURL: nil,
                            onboardingComplete: true,
                            createdAt: .now
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(secondaryText.opacity(0.5))
                    #endif
                }

                Spacer().frame(height: 52)
            }
            .padding(.horizontal, 32)
        }
    }

    private var backgroundColor: Color {
        #if os(iOS)
        colorScheme == .dark ? .black : Color(.systemBackground)
        #else
        colorScheme == .dark ? .black : Color(nsColor: .windowBackgroundColor)
        #endif
    }

    private var primaryText: Color { colorScheme == .dark ? .white : .primary }
    private var secondaryText: Color { colorScheme == .dark ? .white.opacity(0.45) : .secondary }
}

#Preview {
    SignInView()
        .environmentObject(AppState())
}
