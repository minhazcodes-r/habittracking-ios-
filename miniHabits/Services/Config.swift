import Foundation

enum Config {
    static let supabaseURL = "https://hmcmvewsvaxujpruruhh.supabase.co"

    static let supabaseAnonKey = resolvedSupabaseAnonKey()

    static var hasValidSupabaseKey: Bool {
        return !supabaseAnonKey.isEmpty && supabaseAnonKey != "YOUR_ANON_KEY_HERE"
    }

    private static func resolvedSupabaseAnonKey() -> String {
        let env = ProcessInfo.processInfo.environment

        for candidate in ["SUPABASE_ANON_KEY", "SUPABASE_KEY"] {
            if let value = env[candidate]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }

        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtY212ZXdzdmF4dWpwcnVydWhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzUzMjAsImV4cCI6MjA5MDU1MTMyMH0.7ZO0GsHg65odlx9fFttmbsw6O3jmn_oGGeClYWyUJLM"
    }
}
