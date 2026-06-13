import Foundation
import UniformTypeIdentifiers

struct DAWImportResult {
    var title: String?
    var bpm: Int?
    var key: String?
    var format: DAWFormat
}

enum DAWFormat: String {
    case logicPro = "Logic Pro"
    case abletonLive = "Ableton Live"
    case flStudio = "FL Studio"
}

enum DAWImportParser {
    static func parse(url: URL) -> DAWImportResult {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "logicx":
            return parseLogic(url: url)
        case "als":
            return parseAbleton(url: url)
        case "flp":
            return parseFL(url: url)
        default:
            return parseLogic(url: url) // fallback: title only
        }
    }

    // Logic Pro: .logicx is a package (directory). BPM lives in projectData.
    private static func parseLogic(url: URL) -> DAWImportResult {
        let title = url.deletingPathExtension().lastPathComponent
        var bpm: Int?

        let projectDataURL = url
            .appendingPathComponent("projectData")
        if let data = try? Data(contentsOf: projectDataURL) {
            // BPM is stored as a big-endian float at a known offset in the binary projectData blob.
            // Look for the "tempo" key pattern in the raw bytes.
            if let tempoString = extractLogicTempo(from: data) {
                bpm = tempoString
            }
        }

        return DAWImportResult(title: title, bpm: bpm, key: nil, format: .logicPro)
    }

    // Ableton Live: .als is a gzipped XML file.
    private static func parseAbleton(url: URL) -> DAWImportResult {
        let title = url.deletingPathExtension().lastPathComponent
        var bpm: Int?
        var key: String?

        guard
            let compressedData = try? Data(contentsOf: url),
            let xmlData = try? (compressedData as NSData).decompressed(using: .zlib) as Data,
            let xmlString = String(data: xmlData, encoding: .utf8)
        else {
            return DAWImportResult(title: title, bpm: nil, key: nil, format: .abletonLive)
        }

        // Extract BPM: <Tempo><LomId Value="0" /><Manual Value="140" />
        if let range = xmlString.range(of: #"<Tempo>.*?<Manual Value="([0-9.]+)""#, options: .regularExpression) {
            let match = String(xmlString[range])
            if let valRange = match.range(of: #"Manual Value="([0-9.]+)""#, options: .regularExpression) {
                let valStr = String(match[valRange])
                    .replacingOccurrences(of: "Manual Value=\"", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                bpm = Int(Double(valStr) ?? 0)
            }
        }

        // Extract key: <ScaleInformation RootNote="0" Name="Major" />
        if let range = xmlString.range(of: #"ScaleInformation RootNote="(\d+)" Name="([^"]+)""#, options: .regularExpression) {
            let match = String(xmlString[range])
            let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
            if let rootRange = match.range(of: #"RootNote="(\d+)""#, options: .regularExpression) {
                let rootStr = String(match[rootRange])
                    .replacingOccurrences(of: "RootNote=\"", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                if let rootInt = Int(rootStr), rootInt < noteNames.count {
                    let noteName = noteNames[rootInt]
                    if match.contains("Minor") {
                        key = "\(noteName) Minor"
                    } else {
                        key = "\(noteName) Major"
                    }
                }
            }
        }

        return DAWImportResult(title: title, bpm: bpm, key: key, format: .abletonLive)
    }

    // FL Studio: .flp binary format. BPM is a 16-bit LE int at a known event ID (156 = 0x9C).
    private static func parseFL(url: URL) -> DAWImportResult {
        let title = url.deletingPathExtension().lastPathComponent
        var bpm: Int?

        guard let data = try? Data(contentsOf: url) else {
            return DAWImportResult(title: title, bpm: nil, key: nil, format: .flStudio)
        }

        // FLP header: "FLhd" magic, then events. Tempo event ID = 156.
        let bytes = [UInt8](data)
        var i = 0
        let magic = [UInt8]("FLhd".utf8)
        guard bytes.prefix(4).elementsEqual(magic) else {
            return DAWImportResult(title: title, bpm: nil, key: nil, format: .flStudio)
        }
        i = 10 // skip header chunk
        // Skip to data chunk "FLdt"
        let dataMagic = [UInt8]("FLdt".utf8)
        while i + 4 < bytes.count {
            if bytes[i..<i+4].elementsEqual(dataMagic) {
                i += 8 // skip "FLdt" + 4-byte length
                break
            }
            i += 1
        }
        // Parse events
        while i < bytes.count {
            let eventID = bytes[i]
            i += 1
            if eventID == 156 && i + 2 <= bytes.count {
                let raw = UInt16(bytes[i]) | (UInt16(bytes[i+1]) << 8)
                bpm = Int(raw)
                break
            }
            // Skip event data based on type range
            if eventID < 64 {
                i += 1
            } else if eventID < 128 {
                i += 2
            } else if eventID < 192 {
                i += 4
            } else if i + 4 <= bytes.count {
                let len = Int(bytes[i]) | (Int(bytes[i+1]) << 8) |
                    (Int(bytes[i+2]) << 16) | (Int(bytes[i+3]) << 24)
                i += 4 + len
            }
        }

        return DAWImportResult(title: title, bpm: bpm, key: nil, format: .flStudio)
    }

    private static func extractLogicTempo(from data: Data) -> Int? {
        // Search for "tempo" as UTF-8 bytes followed by a float value in the binary blob.
        let tempoBytes = [UInt8]("tempo".utf8)
        let bytes = [UInt8](data)
        for i in 0..<(bytes.count - tempoBytes.count - 8) {
            if bytes[i..<i+tempoBytes.count].elementsEqual(tempoBytes) {
                // BPM value is a 4-byte big-endian float nearby
                for offset in 1...16 {
                    let pos = i + tempoBytes.count + offset
                    guard pos + 4 <= bytes.count else { break }
                    var floatBits: UInt32 = 0
                    floatBits |= UInt32(bytes[pos]) << 24
                    floatBits |= UInt32(bytes[pos+1]) << 16
                    floatBits |= UInt32(bytes[pos+2]) << 8
                    floatBits |= UInt32(bytes[pos+3])
                    let value = Float(bitPattern: floatBits)
                    if value > 40 && value < 300 {
                        return Int(value)
                    }
                }
            }
        }
        return nil
    }
}
