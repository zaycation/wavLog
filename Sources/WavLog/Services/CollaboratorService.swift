import Foundation
import Supabase

private struct CollaboratorInsert: Encodable {
    let projectID: String
    let userID: String
    let invitedBy: String

    enum CodingKeys: String, CodingKey {
        case projectID = "project_id"
        case userID = "user_id"
        case invitedBy = "invited_by"
    }
}

struct Collaborator: Identifiable, Decodable {
    let userID: String
    let projectID: String
    let invitedBy: String
    let invitedAt: Date
    var profile: UserProfile?

    var id: String { userID }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case projectID = "project_id"
        case invitedBy = "invited_by"
        case invitedAt = "invited_at"
    }
}

@MainActor
final class CollaboratorService: ObservableObject {
    static let shared = CollaboratorService()

    private let client = SupabaseClient.shared

    func fetchCollaborators(projectID: String) async throws -> [UserProfile] {
        let rows: [Collaborator] = try await client
            .from("project_collaborators")
            .select()
            .eq("project_id", value: projectID)
            .execute()
            .value

        var profiles: [UserProfile] = []
        for row in rows {
            if let profile = try? await ProfileService.shared.fetchProfile(userID: row.userID) {
                profiles.append(profile)
            }
        }
        return profiles
    }

    func addCollaborator(projectID: String, userID: String) async throws {
        let myID = try await client.auth.session.user.id.uuidString
        let insert = CollaboratorInsert(
            projectID: projectID,
            userID: userID,
            invitedBy: myID
        )
        try await client
            .from("project_collaborators")
            .insert(insert)
            .execute()
    }

    func removeCollaborator(projectID: String, userID: String) async throws {
        try await client
            .from("project_collaborators")
            .delete()
            .eq("project_id", value: projectID)
            .eq("user_id", value: userID)
            .execute()
    }

    func searchUsers(query: String) async throws -> [UserProfile] {
        let profiles: [UserProfile] = try await client
            .from("profiles")
            .select()
            .ilike("display_name", pattern: "%\(query)%")
            .limit(20)
            .execute()
            .value
        return profiles
    }
}
