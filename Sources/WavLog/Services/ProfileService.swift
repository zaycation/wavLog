import Foundation
import Supabase
import UIKit

private struct ProfileOnboardingUpdate: Encodable {
    let displayName: String
    let onboardingComplete: Bool = true

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case onboardingComplete = "onboarding_complete"
    }
}

private struct ProfileNameUpdate: Encodable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

@MainActor
final class ProfileService: ObservableObject {
    static let shared = ProfileService()

    private let client = SupabaseClient.shared

    func fetchProfile(userID: String) async throws -> UserProfile {
        return try await client
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .single()
            .execute()
            .value
    }

    func completeOnboarding(displayName: String) async throws {
        let userID = try await client.auth.session.user.id.uuidString
        try await client
            .from("profiles")
            .update(ProfileOnboardingUpdate(displayName: displayName))
            .eq("id", value: userID)
            .execute()
    }

    func updateDisplayName(_ name: String) async throws {
        let userID = try await client.auth.session.user.id.uuidString
        try await client
            .from("profiles")
            .update(ProfileNameUpdate(displayName: name))
            .eq("id", value: userID)
            .execute()
    }

    func fetchActivityCounts(userID: String) async throws -> [ActivityDay] {
        let since = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
        let sinceISO = ISO8601DateFormatter().string(from: since)

        let projects: [[String: String]] = try await client
            .from("projects")
            .select("created_at")
            .eq("owner_id", value: userID)
            .gte("created_at", value: sinceISO)
            .execute()
            .value

        let bounces: [[String: String]] = try await client
            .from("bounces")
            .select("created_at")
            .eq("uploader_id", value: userID)
            .gte("created_at", value: sinceISO)
            .execute()
            .value

        let comments: [[String: String]] = try await client
            .from("comments")
            .select("created_at")
            .eq("author_id", value: userID)
            .gte("created_at", value: sinceISO)
            .execute()
            .value

        let formatter = ISO8601DateFormatter()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"

        var counts: [String: Int] = [:]
        let allDates = (projects + bounces + comments)
            .compactMap { $0["created_at"] }
            .compactMap { formatter.date(from: $0) }

        for date in allDates {
            let key = dayFormatter.string(from: date)
            counts[key, default: 0] += 1
        }

        return counts.map { ActivityDay(dateString: $0.key, count: $0.value) }
            .sorted { $0.dateString < $1.dateString }
    }

    private struct AvatarURLUpdate: Encodable {
        let avatarURL: String

        enum CodingKeys: String, CodingKey {
            case avatarURL = "avatar_url"
        }
    }

    func uploadAvatar(imageData: Data) async throws -> String {
        let userID = try await client.auth.session.user.id.uuidString.lowercased()
        let fileName = "\(userID)/avatar.jpg"

        guard let uiImage = UIImage(data: imageData),
              let jpegData = uiImage.jpegData(compressionQuality: 0.7)
        else {
            throw NSError(domain: "ProfileService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        try await client.storage
            .from("avatars")
            .upload(
                fileName,
                data: jpegData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        let publicURL = try client.storage
            .from("avatars")
            .getPublicURL(path: fileName)
            .absoluteString + "?t=\(Int(Date().timeIntervalSince1970))"

        try await client
            .from("profiles")
            .update(AvatarURLUpdate(avatarURL: publicURL))
            .eq("id", value: userID)
            .execute()

        return publicURL
    }
}

struct ActivityDay: Identifiable {
    var id: String {
        dateString
    }

    let dateString: String
    let count: Int
}
