import AuthenticationServices
import Foundation
import Supabase

private struct ProfileUpsert: Encodable {
    let id: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

private let knownUserKey = "wavlog.known_apple_user"

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    private let client = SupabaseClient.shared

    // True if this device has successfully signed in before — drives invite gate bypass.
    var hasStoredAppleUser: Bool {
        UserDefaults.standard.string(forKey: knownUserKey) != nil
    }

    func clearStoredAppleUser() {
        UserDefaults.standard.removeObject(forKey: knownUserKey)
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> UserProfile {
        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingToken
        }

        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: token)
        )

        let profile = try await fetchOrCreateProfile(credential: credential)

        // Persist that this device has seen a successful sign-in
        UserDefaults.standard.set(credential.user, forKey: knownUserKey)

        return profile
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func restoreSession() async throws -> UserProfile? {
        guard (try? await client.auth.session) != nil else { return nil }
        return try await fetchCurrentProfile()
    }

    func fetchCurrentProfile() async throws -> UserProfile {
        guard let userID = try? await client.auth.session.user.id.uuidString else {
            throw AuthError.notAuthenticated
        }
        let profile: UserProfile = try await client
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .single()
            .execute()
            .value
        return profile
    }

    private func fetchOrCreateProfile(
        credential: ASAuthorizationAppleIDCredential
    ) async throws -> UserProfile {
        guard let userID = try? await client.auth.session.user.id.uuidString else {
            throw AuthError.notAuthenticated
        }

        if let existing: UserProfile = try? await client
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .single()
            .execute()
            .value {
            return existing
        }

        let displayName = [
            credential.fullName?.givenName,
            credential.fullName?.familyName
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        let name = displayName.isEmpty ? "New User" : displayName

        let profile: UserProfile = try await client
            .from("profiles")
            .upsert(ProfileUpsert(id: userID, displayName: name))
            .select()
            .single()
            .execute()
            .value
        return profile
    }

    enum AuthError: LocalizedError {
        case missingToken
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .missingToken: "Could not read Apple identity token."
            case .notAuthenticated: "No active session."
            }
        }
    }
}
