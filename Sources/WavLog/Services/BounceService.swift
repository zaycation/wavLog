import Foundation
import Supabase

private struct BounceInsert: Encodable {
    let projectID: String
    let uploaderID: String
    let storagePath: String
    let versionNote: String?

    enum CodingKeys: String, CodingKey {
        case projectID = "project_id"
        case uploaderID = "uploader_id"
        case storagePath = "storage_path"
        case versionNote = "version_note"
    }
}

@MainActor
final class BounceService: ObservableObject {
    static let shared = BounceService()

    private let client = SupabaseClient.shared

    func fetchBounces(projectID: String) async throws -> [Bounce] {
        return try await client
            .from("bounces")
            .select()
            .eq("project_id", value: projectID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func uploadBounce(
        projectID: String,
        fileURL: URL,
        versionNote: String?
    ) async throws -> Bounce {
        let userID = try await client.auth.session.user.id.uuidString
        let ext = fileURL.pathExtension.lowercased()
        guard ext == "wav" || ext == "m4a" else {
            throw BounceError.unsupportedFormat
        }

        let data = try Data(contentsOf: fileURL)
        guard data.count <= 100 * 1024 * 1024 else {
            throw BounceError.fileTooLarge
        }

        let storagePath = "\(userID)/\(projectID)/\(UUID().uuidString).\(ext)"
        try await client.storage
            .from("audio")
            .upload(
                storagePath,
                data: data,
                options: FileOptions(contentType: ext == "wav" ? "audio/wav" : "audio/mp4")
            )

        let insert = BounceInsert(
            projectID: projectID,
            uploaderID: userID,
            storagePath: storagePath,
            versionNote: versionNote.flatMap { $0.isEmpty ? nil : $0 }
        )
        // Split insert + fetch to avoid RETURNING * hitting SELECT RLS policy
        try await client
            .from("bounces")
            .insert(insert)
            .execute()

        return try await client
            .from("bounces")
            .select()
            .eq("storage_path", value: storagePath)
            .single()
            .execute()
            .value
    }

    func signedURL(for bounce: Bounce) async throws -> URL {
        return try await client.storage
            .from("audio")
            .createSignedURL(path: bounce.storagePath, expiresIn: 3600)
    }

    func deleteBounce(_ bounce: Bounce) async throws {
        try await client.storage
            .from("audio")
            .remove(paths: [bounce.storagePath])
        try await client
            .from("bounces")
            .delete()
            .eq("id", value: bounce.id)
            .execute()
    }

    // MARK: - Error

    enum BounceError: LocalizedError {
        case unsupportedFormat
        case fileTooLarge

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat: "Only .wav and .m4a files are supported."
            case .fileTooLarge: "File exceeds the 100 MB limit."
            }
        }
    }
}
