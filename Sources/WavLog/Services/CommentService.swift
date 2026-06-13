import Foundation
import Supabase

private struct CommentInsert: Encodable {
    let projectID: String
    let authorID: String
    let body: String
    let parentID: String?

    enum CodingKeys: String, CodingKey {
        case projectID = "project_id"
        case authorID = "author_id"
        case body
        case parentID = "parent_id"
    }
}

@MainActor
final class CommentService: ObservableObject {
    static let shared = CommentService()

    private let client = SupabaseClient.shared

    func fetchComments(projectID: String) async throws -> [Comment] {
        let comments: [Comment] = try await client
            .from("comments")
            .select()
            .eq("project_id", value: projectID)
            .order("created_at", ascending: true)
            .execute()
            .value
        return comments
    }

    func postComment(projectID: String, body: String, parentID: String? = nil) async throws -> Comment {
        let userID = try await client.auth.session.user.id.uuidString
        let insert = CommentInsert(
            projectID: projectID,
            authorID: userID,
            body: body,
            parentID: parentID
        )
        // Split insert + fetch to avoid RETURNING * hitting SELECT RLS policy
        try await client
            .from("comments")
            .insert(insert)
            .execute()

        let comments: [Comment] = try await client
            .from("comments")
            .select()
            .eq("project_id", value: projectID)
            .eq("author_id", value: userID)
            .eq("body", value: body)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        guard let comment = comments.first else {
            throw CommentError.insertFailed
        }
        return comment
    }

    func resolveComment(_ comment: Comment) async throws -> Comment {
        try await client
            .from("comments")
            .update(["is_resolved": true])
            .eq("id", value: comment.id)
            .execute()

        var updated = comment
        updated.isResolved = true
        return updated
    }

    func deleteComment(_ comment: Comment) async throws {
        try await client
            .from("comments")
            .delete()
            .eq("id", value: comment.id)
            .execute()
    }

    enum CommentError: LocalizedError {
        case insertFailed
        var errorDescription: String? { "Failed to post comment." }
    }
}
