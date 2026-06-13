import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    var displayName: String
    var avatarURL: String?
    var onboardingComplete: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case onboardingComplete = "onboarding_complete"
        case createdAt = "created_at"
    }
}
