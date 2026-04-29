import Foundation

enum Config {
    static let supabaseURL = "https://hmcmvewsvaxujpruruhh.supabase.co"

    static let supabaseAnonKey: String = {
        let env = ProcessInfo.processInfo.environment
        let candidates = ["SUPABASE_ANON_KEY", "SUPABASE_KEY"]

        for keyName in candidates {
            if let value = env[keyName]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }

        #if DEBUG
        print("⚠️ Supabase anon key is not configured. Set SUPABASE_ANON_KEY in your scheme environment variables.")
        #endif

        return "YOUR_ANON_KEY_HERE"
    }()
}
