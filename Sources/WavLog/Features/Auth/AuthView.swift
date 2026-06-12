import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("WavLog")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("Your music project journal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                handleSignIn(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(maxWidth: 320)
            .frame(height: 50)

            Spacer()
        }
        .padding()
        .preferredColorScheme(.dark)
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success:
            // TODO: pass credential to Supabase auth
            appState.isAuthenticated = true
        case .failure(let error):
            print("Sign in failed: \(error)")
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AppState())
}
