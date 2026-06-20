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

    // Populated by Music Understanding auto-analysis (iOS 27+ / macOS 27+). See PRD 5.6.
    var detectedBPM: Int? = nil
    var detectedKey: String? = nil
    var waveformData: [Double]? = nil
    var structureData: [TrackSection]? = nil
    var instrumentData: [InstrumentActivity]? = nil
    var loudnessData: [LoudnessSample]? = nil

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
        case detectedBPM = "detected_bpm"
        case detectedKey = "detected_key"
        case waveformData = "waveform_data"
        case structureData = "structure_data"
        case instrumentData = "instrument_data"
        case loudnessData = "loudness_data"
    }

    /// Total span covered by structure/instrument analysis, for proportional timeline rendering.
    var analyzedDuration: Double {
        let structureEnd = structureData?.map(\.end).max() ?? 0
        let instrumentEnd = instrumentData?.map(\.end).max() ?? 0
        return max(structureEnd, instrumentEnd, 1)
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
        updatedAt: .now,
        detectedBPM: 140,
        detectedKey: "A Minor",
        waveformData: (0 ..< 60).map { _ in Double.random(in: 0.15...1) },
        structureData: [
            TrackSection(label: "intro", start: 0, end: 8),
            TrackSection(label: "verse", start: 8, end: 24),
            TrackSection(label: "chorus", start: 24, end: 36),
            TrackSection(label: "bridge", start: 36, end: 44),
        ],
        instrumentData: [
            InstrumentActivity(instrument: "drums", start: 4, end: 44),
            InstrumentActivity(instrument: "bass", start: 8, end: 44),
            InstrumentActivity(instrument: "vocals", start: 12, end: 36),
        ],
        loudnessData: (0 ..< 60).map { LoudnessSample(time: Double($0) * 0.73, value: Double.random(in: 0.15...1)) }
    )
}
