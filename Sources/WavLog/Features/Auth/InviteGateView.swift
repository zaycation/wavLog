import SwiftUI

// Shown only to brand-new users who the backend has never seen.
// Flow: enter code → validate → SIWA appears → sign in → onboarding or app
struct InviteGateView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @State private var code = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var inviteValidated = false

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                AnimatedWaveformView()
                    .frame(height: 130)
                    .padding(.horizontal, 12)

                Spacer().frame(height: 40)

                Text("WavLog")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)

                Spacer().frame(height: 56)

                if inviteValidated {
                    signInSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    codeEntrySection
                        .transition(.opacity)
                }

                Spacer()

                Text("WavLog is invite only.")
                    .font(.caption)
                    .foregroundStyle(subtleText)

                Spacer().frame(height: 44)
            }
            .padding(.horizontal, 32)
        }
        .animation(.easeInOut(duration: 0.3), value: inviteValidated)
    }

    // MARK: - Sections

    private var codeEntrySection: some View {
        VStack(spacing: 12) {
            TextField("Invite code", text: $code)
                .textCase(.uppercase)
                .autocorrectionDisabled()
            #if os(iOS)
                .textInputAutocapitalization(.characters)
            #endif
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: code) { _, new in
                    code = String(
                        new.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(8)
                    )
                    errorMessage = nil
                }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await validate() }
            } label: {
                Group {
                    if isValidating {
                        ProgressView().tint(.black)
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(code.count == 8 ? primaryText : primaryText.opacity(0.15))
                .foregroundStyle(code.count == 8 ? backgroundColor : subtleText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(code.count != 8 || isValidating)
        }
        .frame(maxWidth: 320)
    }

    private var signInSection: some View {
        SignInWithAppleSection(validatedCode: code) { profile in
            appState.currentUser = profile
            appState.onboardingComplete = profile.onboardingComplete
            appState.isAuthenticated = true
            appState.isKnownUser = true
        } onError: { message in
            errorMessage = message
            inviteValidated = false
        }
    }

    // MARK: - Actions

    private func validate() async {
        isValidating = true
        errorMessage = nil
        defer { isValidating = false }
        do {
            try await InviteService.shared.validateCode(code)
            inviteValidated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        #if os(iOS)
            colorScheme == .dark ? .black : Color(.systemBackground)
        #else
            colorScheme == .dark ? .black : Color(nsColor: .windowBackgroundColor)
        #endif
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var subtleText: Color {
        colorScheme == .dark ? .white.opacity(0.3) : .secondary
    }

    private var fieldBackground: Color {
        colorScheme == .dark ? .white.opacity(0.07) : .black.opacity(0.05)
    }
}

#Preview {
    InviteGateView()
        .environmentObject(AppState())
}
