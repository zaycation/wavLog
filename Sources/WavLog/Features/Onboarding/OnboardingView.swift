import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var displayName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var nameFocused: Bool

    private var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Text("What should we call you?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(primaryText)
                    Text("This is how other collaborators will see you.")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: 40)

                TextField("Display name", text: $displayName)
                    .focused($nameFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 22, weight: .medium))
                    .padding()
                    .background(fieldBackground)
                    .foregroundStyle(primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }

                Spacer()

                Button {
                    Task { await save() }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(colorScheme == .dark ? .black : .white)
                        } else {
                            Text("Let's go")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: 320)
                    .frame(height: 52)
                    .background(buttonBackground)
                    .foregroundStyle(buttonText)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue || isSaving)

                Spacer().frame(height: 52)
            }
        }
        .onAppear {
            nameFocused = true
            if displayName.isEmpty,
               let current = appState.currentUser?.displayName,
               current != "New User" {
                displayName = current
            }
        }
    }

    private var backgroundColor: Color {
        #if os(iOS)
        return colorScheme == .dark ? .black : Color(.systemBackground)
        #else
        return colorScheme == .dark ? .black : Color(nsColor: .windowBackgroundColor)
        #endif
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.45) : .secondary
    }

    private var fieldBackground: Color {
        #if os(iOS)
        return colorScheme == .dark ? .white.opacity(0.07) : Color(.secondarySystemBackground)
        #else
        return colorScheme == .dark ? .white.opacity(0.07) : Color(nsColor: .controlBackgroundColor)
        #endif
    }

    private var buttonBackground: Color {
        guard canContinue else {
            return colorScheme == .dark ? .white.opacity(0.15) : Color(.systemGray4)
        }
        return colorScheme == .dark ? .white : .black
    }

    private var buttonText: Color {
        guard canContinue else { return .secondary }
        return colorScheme == .dark ? .black : .white
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let name = displayName.trimmingCharacters(in: .whitespaces)
            try await ProfileService.shared.completeOnboarding(displayName: name)
            appState.currentUser?.displayName = name
            appState.currentUser?.onboardingComplete = true
            appState.onboardingComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
