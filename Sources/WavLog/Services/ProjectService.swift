import Foundation
import Supabase

@MainActor
final class ProjectService: ObservableObject {
    static let shared = ProjectService()

    private let client = SupabaseClient.shared

    func fetchProjects() async throws -> [Project] {
        let userID = try await client.auth.session.user.id.uuidString

        let owned: [Project] = try await client
            .from("projects")
            .select()
            .eq("owner_id", value: userID)
            .order("updated_at", ascending: false)
            .execute()
            .value

        struct CollabRow: Decodable {
            let projectID: String
            enum CodingKeys: String, CodingKey { case projectID = "project_id" }
        }
        let collabRows: [CollabRow] = try await client
            .from("project_collaborators")
            .select("project_id")
            .eq("user_id", value: userID)
            .execute()
            .value
        let collabIDs = collabRows.map(\.projectID)

        guard !collabIDs.isEmpty else { return owned }

        let collab: [Project] = try await client
            .from("projects")
            .select()
            .in("id", values: collabIDs)
            .order("updated_at", ascending: false)
            .execute()
            .value

        var seen = Set<String>()
        return (owned + collab).filter { seen.insert($0.id).inserted }
    }

    func createProject(_ draft: ProjectDraft) async throws -> Project {
        let userID = try await client.auth.session.user.id.uuidString
        let insert = ProjectInsert(
            ownerID: userID,
            title: draft.title,
            bpm: draft.bpm,
            key: draft.key.flatMap { $0.isEmpty ? nil : $0 },
            genre: draft.genre.flatMap { $0.isEmpty ? nil : $0 },
            influences: draft.influences.flatMap { $0.isEmpty ? nil : $0 },
            bandlabURL: draft.bandlabURL.flatMap { $0.isEmpty ? nil : $0 }
        )
        // Insert without .select() to avoid RETURNING * hitting the SELECT RLS policy.
        // Then fetch the newly created row separately via the owner_id filter.
        try await client
            .from("projects")
            .insert(insert)
            .execute()

        let project: Project = try await client
            .from("projects")
            .select()
            .eq("owner_id", value: userID)
            .eq("title", value: draft.title)
            .order("created_at", ascending: false)
            .limit(1)
            .single()
            .execute()
            .value
        return project
    }

    func updateStatus(_ project: Project, status: Project.Status) async throws -> Project {
        let updated: Project = try await client
            .from("projects")
            .update(["status": status.rawValue])
            .eq("id", value: project.id)
            .select()
            .single()
            .execute()
            .value
        return updated
    }

    func updateNotes(_ project: Project, notes: String) async throws {
        try await client
            .from("projects")
            .update(["lyrics_notes": notes])
            .eq("id", value: project.id)
            .execute()
    }

    func archiveProject(_ project: Project) async throws {
        try await client
            .from("projects")
            .update(["is_archived": true])
            .eq("id", value: project.id)
            .execute()
    }

    func deleteProject(_ project: Project) async throws {
        try await client
            .from("projects")
            .delete()
            .eq("id", value: project.id)
            .execute()
    }
}

struct ProjectDraft {
    var title: String
    var bpm: Int?
    var key: String?
    var genre: String?
    var influences: String?
    var bandlabURL: String?
}

private struct ProjectInsert: Encodable {
    let ownerID: String
    let title: String
    let bpm: Int?
    let key: String?
    let genre: String?
    let influences: String?
    let bandlabURL: String?
    let status = "wip"

    enum CodingKeys: String, CodingKey {
        case ownerID = "owner_id"
        case title
        case bpm
        case key
        case genre
        case influences
        case bandlabURL = "bandlab_url"
        case status
    }
}
