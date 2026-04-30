import SwiftUI
import Supabase
import Combine
import AuthenticationServices

@MainActor
class AuthStore: ObservableObject {
    @Published var user: User?
    @Published var isLoading = true
    @Published var isAuthenticated = false
    @Published var configurationError: String?

    init() {
        Task { await bootstrap() }
    }

    func bootstrap() async {
        guard Config.hasValidSupabaseKey else {
            configurationError = "Missing SUPABASE_ANON_KEY. Set it in the app environment before logging in."
            isLoading = false
            return
        }

        do {
            let session = try await supabase.auth.session
            self.user = session.user
            self.isAuthenticated = true
        } catch {
            self.user = nil
            self.isAuthenticated = false
        }
        self.isLoading = false

        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                if event == .signedIn {
                    self.user = session?.user
                    self.isAuthenticated = true
                } else if event == .signedOut {
                    self.user = nil
                    self.isAuthenticated = false
                }
            }
        }
    }

    func login(email: String, password: String) async -> String? {
        do {
            try await supabase.auth.signIn(email: email, password: password)
            return nil
        } catch { return error.localizedDescription }
    }

    func signup(name: String, email: String, password: String) async -> String? {
        do {
            try await supabase.auth.signUp(email: email, password: password, data: ["full_name": .string(name)])
            return nil
        } catch { return error.localizedDescription }
    }

    func logout() async {
        try? await supabase.auth.signOut()
    }

    func loginWithGoogle() async -> String? {
        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "minihabits://login-callback")
            ) { session in
                session.prefersEphemeralWebBrowserSession = false
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
