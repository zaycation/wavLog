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
        let result = try await session.analyze()

        // StructureResult only exposes time-range boundaries, not section names,
        // so labels are synthesized rather than read from the framework.
        let structure = (result.structure?.sections ?? []).enumerated().map { index, range in
            TrackSection(
                label: "Section \(index + 1)",
                start: range.start.seconds,
                end: (range.start + range.duration).seconds
            )
        }

        let instruments = (result.instrumentActivity?.ranges ?? [:]).flatMap { instrument, ranges in
            ranges.map {
                InstrumentActivity(
                    instrument: instrument.rawValue,
                    start: $0.start.seconds,
                    end: ($0.start + $0.duration).seconds
                )
            }
        }

        let loudness = (result.loudness?.momentary ?? []).map {
            LoudnessSample(time: $0.time.seconds, value: Double($0.value))
        }

        print("MUSIC UNDERSTANDING DEBUG: structure=\(structure.count) instruments=\(instruments.count) loudness=\(loudness.count) rhythm=\(String(describing: result.rhythm)) key=\(String(describing: result.key)) loudnessResult=\(String(describing: result.loudness))")

        let keySignature = result.key?.ranges.first?.value
        return AnalysisResult(
            bpm: result.rhythm?.beatsPerMinute.map { Int($0.rounded()) },
            key: keySignature.map(Self.keyDisplayName),
            structure: structure,
            instruments: instruments,
            loudness: loudness,
            waveform: Self.resample(loudness.map(\LoudnessSample.value), targetCount: 100)
        )
    }

    // Tonic/mode case-name casing isn't fully confirmed against the SDK yet, so this
    // uses reflection instead of an exhaustive switch to stay compile-safe.
    @available(iOS 27.0, macOS 27.0, *)
    private static func keyDisplayName(_ signature: KeyResult.KeySignature) -> String {
        "\(String(describing: signature.tonic).capitalized) \(String(describing: signature.mode).capitalized)"
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
