import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { CalendarScreenView() }
                .tabItem { Label("Calendar", systemImage: "calendar") }
            NavigationStack { AnalyticsView() }
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(.white)
    }
}
