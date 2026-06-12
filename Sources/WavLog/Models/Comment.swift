import Foundation

struct Comment: Identifiable, Codable {
    let id: String
    let projectID: String
    let authorID: String
    var parentID: String?
    var body: String
    var audioPath: String?
    var isResolved: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case projectID = "project_id"
        case authorID = "author_id"
        case parentID = "parent_id"
        case body
        case audioPath = "audio_path"
        case isResolved = "is_resolved"
        case createdAt = "created_at"
    }
}
