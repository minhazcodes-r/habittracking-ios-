import Foundation

enum Config {
    static let supabaseURL = "https://hmcmvewsvaxujpruruhh.supabase.co"

    // Merge-conflict-safe approach:
    // - Keep the original placeholder fallback.
    // - Prefer runtime env values when provided by the scheme.
    static let supabaseAnonKey = resolvedSupabaseAnonKey()

    private static func resolvedSupabaseAnonKey() -> String {
        let env = ProcessInfo.processInfo.environment

        for candidate in ["SUPABASE_ANON_KEY", "SUPABASE_KEY"] {
            if let value = env[candidate]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }

        return "YOUR_ANON_KEY_HERE"
    }
}
