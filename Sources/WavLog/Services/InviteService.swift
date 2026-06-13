import Foundation
import Supabase

private struct InviteInsert: Encodable {
    let code: String
    let createdBy: String

    enum CodingKeys: String, CodingKey {
        case code
        case createdBy = "created_by"
    }
}

struct Invite: Identifiable, Decodable {
    let id: String
    let code: String
    let createdBy: String
    let usedBy: String?
    let usedAt: Date?
    let createdAt: Date

    var isUsed: Bool { usedBy != nil }

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case createdBy = "created_by"
        case usedBy = "used_by"
        case usedAt = "used_at"
        case createdAt = "created_at"
    }
}

@MainActor
final class InviteService: ObservableObject {
    static let shared = InviteService()

    private let client = SupabaseClient.shared

    func generateInvite() async throws -> Invite {
        let userID = try await client.auth.session.user.id.uuidString
        let code = makeCode()
        let insert = InviteInsert(code: code, createdBy: userID)
        try await client
            .from("invites")
            .insert(insert)
            .execute()
        let invite: Invite = try await client
            .from("invites")
            .select()
            .eq("code", value: code)
            .single()
            .execute()
            .value
        return invite
    }

    func fetchMyInvites() async throws -> [Invite] {
        let userID = try await client.auth.session.user.id.uuidString
        let invites: [Invite] = try await client
            .from("invites")
            .select()
            .eq("created_by", value: userID)
            .order("created_at", ascending: false)
            .execute()
            .value
        return invites
    }

    // Uses a security-definer RPC to bypass RLS — caller may not be authenticated yet.
    func validateCode(_ code: String) async throws {
        struct Params: Encodable { let invite_code: String }
        struct Result: Decodable { let valid: Bool }

        let result: Result = try await client
            .rpc("validate_invite_code", params: Params(invite_code: code.uppercased()))
            .execute()
            .value
        guard result.valid else {
            throw InviteError.invalid
        }
    }

    // Uses a security-definer RPC so the update runs as postgres, not the anon role.
    func markUsed(code: String) async throws {
        struct Params: Encodable { let invite_code: String }
        try await client
            .rpc("mark_invite_used", params: Params(invite_code: code.uppercased()))
            .execute()
    }

    private func makeCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }

    enum InviteError: LocalizedError {
        case invalid

        var errorDescription: String? {
            "That invite code is invalid or has already been used."
        }
    }
}
