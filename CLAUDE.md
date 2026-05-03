# miniHabits — Claude project guide

iOS habit tracker. SwiftUI + Supabase backend.

## Project facts

- **Path:** `/Volumes/MinhazStorage/miniHabits2/miniHabits` — always launch Claude from here. Do not `cd` into the *other* repo at `/Volumes/MinhazStorage/miniHabits/HabitTrackingIOS`; it is stale and unrelated.
- **Xcode project:** `miniHabits.xcodeproj`, scheme `miniHabits`, bundle ID `minhas.miniHabits`
- **Deployment target:** iOS 26.4
- **Backend:** Supabase. URL is hardcoded in `miniHabits/Services/Config.swift`; anon key has an env override.
- **Auth:** Supabase email/password works. Google OAuth is the active in-progress feature (see Active task).
- **Git remote:** `git@github.com:MinhazCodes-R/HabitTracking-IOS-.git`

## Build & test commands

```bash
# Build for iPhone 17 simulator (iOS 26.4)
xcodebuild -project miniHabits.xcodeproj -scheme miniHabits \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Quiet build (used by hooks)
xcodebuild -project miniHabits.xcodeproj -scheme miniHabits \
  -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build

# Boot the simulator if not already booted
xcrun simctl boot 'iPhone 17' 2>/dev/null || true
open -a Simulator
```

There is no XCTest target yet. Verification = clean build + manual run in the simulator.

## Project layout

```
miniHabits/
├── miniHabitsApp.swift        — entry point; mounts AppRootView with AuthStore + HabitsStore
├── App/
│   ├── AppRootView.swift      — auth-gated root (Login vs MainTabView)
│   └── MainTabView.swift      — tab bar host
├── Core/
│   ├── Theme/                 — Colors, Typography
│   └── Utilities/             — DateFormatting, HabitConfig
├── Features/                  — one folder per screen (Home, HabitDetail, Calendar, Analytics, Profile, Auth)
├── Models/                    — Habit, HabitLog, FeedbackMessage (Codable, Supabase-backed)
├── Services/                  — Config (env), SupabaseClient (singleton `supabase`)
└── Stores/                    — ObservableObject view-models: AuthStore, HabitsStore, AnalyticsStore, CalendarStore
```

Pattern: SwiftUI views observe `@StateObject`/`@EnvironmentObject` stores. Stores own Supabase calls. Models stay dumb (Codable structs).

## Conventions

- **Imports:** SwiftUI files that use `Combine` publishers must `import Combine` (Swift's stdlib doesn't auto-import it). Files that touch Supabase types (`User.id`, `AnyJSON`) must `import Supabase`.
- **Async:** Use Swift Concurrency (`async`/`await`, `Task {}`). Don't introduce Combine pipelines unless the codebase already uses them in that file.
- **Errors:** Stores expose async functions that return `String?` — `nil` on success, error message on failure. Views display the string.
- **No XCTest yet** — don't introduce a test target without asking. Verify changes with a CLI build.
- **Don't commit secrets.** Anon key may live in env (`SUPABASE_ANON_KEY`); never paste service-role keys anywhere.

## Active task — Google OAuth login

The "Continue with Google" button in `miniHabits/Features/Auth/LoginView.swift:44` has an empty action. Web app used redirect-based OAuth which doesn't work on iOS.

**Decisions locked in:**
- URL scheme: `minihabits`
- Callback URL: `minihabits://login-callback`
- Approach: custom URL scheme (not Universal Links — overkill for personal app)

**Blocked on user (need yes/no):** Has Google provider been enabled in Supabase dashboard? If no:
1. Supabase → Authentication → Providers → Google → enable
2. Need a Google Cloud OAuth web client (Supabase handles the callback)
3. Supabase → Authentication → URL Configuration → Redirect URLs → add `minihabits://login-callback`

**Code changes once unblocked:**
1. `miniHabits.xcodeproj` — add URL Type for scheme `minihabits` (Target → Info → URL Types)
2. `Stores/AuthStore.swift` — add `loginWithGoogle()` using `supabase.auth.signInWithOAuth(provider: .google, redirectTo: ...)`
3. `miniHabitsApp.swift` — add `.onOpenURL { url in Task { try? await supabase.auth.session(from: url) } }`
4. `LoginView.swift:44` and `SignupView.swift` — wire the buttons to `authStore.loginWithGoogle()`

## Queued work (deferred)

- **App icon swap** — user has an "m/m/m/m" 4-quadrant logo (white on black). Save as 1024×1024 PNG into `miniHabits/Assets.xcassets/AppIcon.appiconset/`. Reference at `/Volumes/MinhazStorage/MiniHabitDocs/m.png` (verify exists first).
- **Home screen widgets** — large task. Needs Widget Extension target, App Group entitlement (`group.minhas.miniHabits`), shared `UserDefaults(suiteName:)` snapshot, AppIntent for in-widget check-off (iOS 17+), per-habit "include in widget" toggle in `HabitDetailView`. Requires user to set signing team and confirm App Group in Xcode capabilities after code lands.

## Cleanups (low priority)

- `miniHabits/ContentView.swift` — leftover Xcode template, now unused. Confirm before deleting.
- `Features/Profile/ProfileView.swift:115` — unused `try?` result (warning).
- `Features/Profile/ProfileView.swift:93` — deprecated `Text + Text` concatenation (iOS 26.0 warning).

## Environment quirks

- This repo lives on an external volume (`/Volumes/MinhazStorage`). If the volume unmounts mid-session the shell dies — relaunch from this dir.
- A previous session's shell died because its starting cwd was a *different* (since-deleted) repo at `/Volumes/MinhazStorage/miniHabits/HabitTrackingIOS`. Always start Claude from this directory.
- Last-known booted simulator: iPhone 17 (iOS 26.4).
