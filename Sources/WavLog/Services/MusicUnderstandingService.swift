import AVFoundation
import Foundation
#if canImport(MusicUnderstanding)
import MusicUnderstanding
#endif

struct AnalysisResult: Equatable {
    var bpm: Int?
    var key: String?
    var structure: [TrackSection]
    var instruments: [InstrumentActivity]
    var loudness: [LoudnessSample]
    var waveform: [Double]

    static let unsupported = AnalysisResult(
        bpm: nil,
        key: nil,
        structure: [],
        instruments: [],
        loudness: [],
        waveform: []
    )
}

struct TrackSection: Codable, Hashable, Identifiable {
    var id: String { "\(label)_\(start)" }
    let label: String
    let start: Double
    let end: Double
}

struct InstrumentActivity: Codable, Hashable, Identifiable {
    var id: String { "\(instrument)_\(start)" }
    let instrument: String
    let start: Double
    let end: Double
}

struct LoudnessSample: Codable, Hashable {
    let time: Double
    let value: Double
}

@MainActor
final class MusicUnderstandingService {
    static let shared = MusicUnderstandingService()

    private init() {}

    enum AnalysisError: LocalizedError {
        case sessionFailed

        var errorDescription: String? {
            "Music Understanding couldn't analyze this bounce."
        }
    }

    func analyze(audioURL: URL) async throws -> AnalysisResult {
        if #available(iOS 27.0, macOS 27.0, *) {
            #if canImport(MusicUnderstanding)
            return try await runSession(audioURL: audioURL)
            #else
            return .unsupported
            #endif
        }
        return .unsupported
    }

    // The MusicUnderstanding framework (WWDC26, iOS 27 / macOS 27+) isn't part of
    // any public SDK yet, so this path only compiles once Xcode ships a toolchain
    // that vends the module. Until then `canImport` keeps it out of the build.
    #if canImport(MusicUnderstanding)
    @available(iOS 27.0, macOS 27.0, *)
    private func runSession(audioURL: URL) async throws -> AnalysisResult {
        let asset = AVAsset(url: audioURL)
        let session = try await MusicUnderstandingSession(asset: asset)
        let result = try await session.analysis(for: asset)

        let structure = result.structure.map {
            TrackSection(
                label: $0.label,
                start: $0.timeRange.start.seconds,
                end: $0.timeRange.end.seconds
            )
        }

        let instruments = result.instrumentActivity.flatMap { activity in
            activity.activeRanges.map {
                InstrumentActivity(
                    instrument: activity.instrument,
                    start: $0.start.seconds,
                    end: $0.end.seconds
                )
            }
        }

        let loudness = result.loudnessCurve.map {
            LoudnessSample(time: $0.time.seconds, value: Double($0.loudness))
        }

        return AnalysisResult(
            bpm: result.tempo.map { Int($0.beatsPerMinute.rounded()) },
            key: result.key?.displayName,
            structure: structure,
            instruments: instruments,
            loudness: loudness,
            waveform: Self.resample(loudness.map(\LoudnessSample.value), targetCount: 100)
        )
    }
    #endif

    nonisolated static func resample(_ values: [Double], targetCount: Int) -> [Double] {
        guard targetCount > 0, values.count > targetCount else { return values }
        let bucketSize = Double(values.count) / Double(targetCount)
        return (0 ..< targetCount).map { bucket in
            let start = Int(Double(bucket) * bucketSize)
            let end = max(start + 1, min(values.count, Int(Double(bucket + 1) * bucketSize)))
            let slice = values[start ..< end]
            return slice.reduce(0, +) / Double(slice.count)
        }
    }
}
