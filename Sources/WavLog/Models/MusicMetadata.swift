import Foundation

enum MusicMetadata {
    static let genres: [String] = [
        // Hip-Hop / R&B
        "Hip-Hop", "Trap", "Drill", "Boom Bap", "Lo-Fi Hip-Hop",
        "R&B", "Alternative R&B", "Soul", "Neo-Soul",
        // Electronic
        "Electronic", "House", "Deep House", "Afro House", "Tech House",
        "Techno", "Ambient", "Synthwave", "Hyperpop", "Jersey Club",
        "Afrobeats", "Amapiano",
        // Pop
        "Pop", "Indie Pop", "Dark Pop", "Bedroom Pop",
        // Rock / Alt
        "Alternative", "Indie", "Rock",
        // Other
        "Reggaeton", "Latin", "Gospel", "Jazz", "Funk",
        "Other"
    ]

    static let keys: [String] = [
        "None",
        "C Major", "C Minor",
        "C# Major", "C# Minor",
        "D Major", "D Minor",
        "D# Major", "D# Minor",
        "E Major", "E Minor",
        "F Major", "F Minor",
        "F# Major", "F# Minor",
        "G Major", "G Minor",
        "G# Major", "G# Minor",
        "A Major", "A Minor",
        "A# Major", "A# Minor",
        "B Major", "B Minor"
    ]
}
