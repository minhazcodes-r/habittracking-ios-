import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        Group {
            if authStore.isLoading {
                ZStack {
                    Color.background.ignoresSafeArea()
                    ProgressView().tint(.white)
                }
            } else if authStore.isAuthenticated {
                MainTabView()
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
