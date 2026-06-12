import Foundation
import Supabase

// Populate these from your Supabase project settings.
// Do NOT commit real credentials — use Xcode build settings or a gitignored Config.swift.
enum SupabaseConfig {
    static let url = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://placeholder.supabase.co")!
    static let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "placeholder-anon-key"
}

extension SupabaseClient {
    static let shared = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey
    )
}
