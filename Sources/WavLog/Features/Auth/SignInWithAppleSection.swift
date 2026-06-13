import AuthenticationServices
import SwiftUI

// Shared SIWA button used by both InviteGateView and SignInView.
struct SignInWithAppleSection: View {
    @Environment(\.colorScheme) private var colorScheme

    var validatedCode: String?
    var onSuccess: (UserProfile) -> Void
    var onError: (String) -> Void

    @State private var isSigningIn = false

    var body: some View {
        VStack(spacing: 10) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                Task { await handleSignIn(result) }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(maxWidth: 320)
            .frame(height: 52)
            .disabled(isSigningIn)
        }
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isSigningIn = true
        defer { isSigningIn = false }

        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            do {
                let profile = try await AuthService.shared.signInWithApple(credential: credential)
                if let code = validatedCode {
                    try? await InviteService.shared.markUsed(code: code)
                }
                onSuccess(profile)
            } catch {
                onError(error.localizedDescription)
            }
        case .failure(let error):
            // Error code 1001 = user cancelled, don't show an error for that
            let nsError = error as NSError
            if nsError.code != 1001 {
                onError(error.localizedDescription)
            }
        }
    }
}
