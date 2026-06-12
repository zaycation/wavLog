import Foundation

struct Bounce: Identifiable, Codable {
    let id: String
    let projectID: String
    let uploaderID: String
    let storagePath: String
    var versionNote: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case projectID = "project_id"
        case uploaderID = "uploader_id"
        case storagePath = "storage_path"
        case versionNote = "version_note"
        case createdAt = "created_at"
    }
}
