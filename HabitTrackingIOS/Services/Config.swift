enum Config {
    private static let defaultSupabaseURL = "https://hmcmvewsvaxujpruruhh.supabase.co"

    static var supabaseURL: String {
        ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? defaultSupabaseURL
    }

    static var supabaseAnonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    }

    static var hasValidSupabaseKey: Bool {
        !supabaseAnonKey.isEmpty && supabaseAnonKey != "YOUR_ANON_KEY_HERE"
    }
}
