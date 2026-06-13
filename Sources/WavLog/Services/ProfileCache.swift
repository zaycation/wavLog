import Foundation
import Supabase

// Lightweight in-memory cache so views don't re-fetch the same profile repeatedly.
@MainActor
final class ProfileCache: ObservableObject {
    static let shared = ProfileCache()

    private var cache: [String: UserProfile] = [:]
    private let client = SupabaseClient.shared

    func displayName(for userID: String) async -> String {
        if let cached = cache[userID] { return cached.displayName }
        guard let profile = try? await ProfileService.shared.fetchProfile(userID: userID) else {
            return "Unknown"
        }
        cache[userID] = profile
        return profile.displayName
    }

    func prefetch(userIDs: [String]) async {
        let missing = userIDs.filter { cache[$0] == nil }
        guard !missing.isEmpty else { return }
        let profiles: [UserProfile] = (try? await client
            .from("profiles")
            .select()
            .in("id", values: missing)
            .execute()
            .value) ?? []
        for profile in profiles {
            cache[profile.id] = profile
        }
    }
}
