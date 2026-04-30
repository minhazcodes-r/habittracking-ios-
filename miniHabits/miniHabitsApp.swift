//
//  miniHabitsApp.swift
//  miniHabits
//
//  Created by Minhaz Rakin on 2026-04-29.
//

import SwiftUI
import Supabase

@main
struct miniHabitsApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var habitsStore = HabitsStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authStore)
                .environmentObject(habitsStore)
                .onOpenURL { url in
                    Task { try? await supabase.auth.session(from: url) }
                }
        }
    }
}
