import Foundation
import Supabase

private let supabaseURL: URL = {
    guard let url = URL(string: Config.supabaseURL) else {
        preconditionFailure("Invalid SUPABASE_URL value: \(Config.supabaseURL)")
    }
    return url
}()

let supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: Config.supabaseAnonKey)
