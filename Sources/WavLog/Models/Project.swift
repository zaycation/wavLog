import Foundation
import SwiftUI

struct Project: Identifiable, Codable, Hashable {
    let id: String
    let ownerID: String
    var title: String
    var bpm: Int?
    var key: String?
    var genre: String?
    var influences: String?
    var bandlabURL: String?
    var status: Status
    var isArchived: Bool
    var lyricsNotes: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case title
        case bpm
        case key
        case genre
        case influences
        case bandlabURL = "bandlab_url"
        case status
        case isArchived = "is_archived"
        case lyricsNotes = "lyrics_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum Status: String, Codable, CaseIterable {
        case wip
        case shared
        case complete

        var displayName: String {
            switch self {
            case .wip: "WIP"
            case .shared: "Shared"
            case .complete: "Complete"
            }
        }

        var color: Color {
            switch self {
            case .wip: .orange
            case .shared: .blue
            case .complete: .green
            }
        }
    }
}

extension Project {
    static let preview = Project(
        id: "preview-id",
        ownerID: "owner-id",
        title: "Dark Summer",
        bpm: 140,
        key: "Am",
        genre: "Trap",
        influences: "Travis Scott, Metro Boomin",
        bandlabURL: nil,
        status: .wip,
        isArchived: false,
        lyricsNotes: nil,
        createdAt: .now,
        updatedAt: .now
    )
}
