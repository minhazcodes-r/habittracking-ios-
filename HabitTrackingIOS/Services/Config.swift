import Foundation

enum Config {
    static let supabaseURL = "https://hmcmvewsvaxujpruruhh.supabase.co"

    static let supabaseAnonKey: String = {
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !key.isEmpty {
            return key
        }

        #if DEBUG
        assertionFailure("SUPABASE_ANON_KEY is not set. Add it in the run scheme environment variables.")
        #endif

        return "YOUR_ANON_KEY_HERE"
    }()
}
