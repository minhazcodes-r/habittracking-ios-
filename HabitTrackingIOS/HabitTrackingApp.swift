import SwiftUI

@main
struct HabitTrackingApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var habitsStore = HabitsStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authStore)
                .environmentObject(habitsStore)
        }
    }
}
