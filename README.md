# miniHabits

A minimalist iOS habit tracker. Build a habit by ticking it off once a day; see your streak grow on the calendar; spot patterns in the analytics tab.

Built with SwiftUI, persisted with Supabase. Personal project — not on the App Store.

<!-- Add a screenshot here once the new app icon is in: -->
<!-- ![miniHabits home screen](docs/screenshot-home.png) -->

## Features

- **Daily habit check-ins** — tap a card on the home screen to log today
- **Calendar view** — month grid showing which days each habit was hit
- **Analytics** — per-habit streaks, completion rate, trend over time
- **Cross-device sync** — Supabase Auth + Postgres backs every change
- **Email/password sign-in** (Google OAuth — in progress, see [Roadmap](#roadmap))

## Tech stack

| Layer | Choice |
|---|---|
| UI | SwiftUI (iOS 26.4+) |
| State | `ObservableObject` stores per domain (Auth, Habits, Analytics, Calendar) |
| Concurrency | Swift Concurrency (`async`/`await`) |
| Backend | Supabase (Postgres + Auth) |
| SDK | [supabase-swift](https://github.com/supabase/supabase-swift) |
| Build | Xcode 26 |

## Project layout

```
miniHabits/
├── miniHabitsApp.swift       — entry point; mounts AppRootView
├── App/
│   ├── AppRootView.swift     — auth-gated root (Login vs MainTabView)
│   └── MainTabView.swift     — tab bar
├── Core/
│   ├── Theme/                — Colors, Typography
│   └── Utilities/            — DateFormatting, HabitConfig
├── Features/                 — one folder per screen
│   ├── Auth/                 — LoginView, SignupView
│   ├── Home/                 — HomeView, HabitCardView, CreateHabitView
│   ├── HabitDetail/          — per-habit detail + settings
│   ├── Calendar/             — month grid view
│   ├── Analytics/            — streak charts
│   └── Profile/              — account + sign-out
├── Models/                   — Habit, HabitLog, FeedbackMessage (Codable)
├── Services/                 — Config, SupabaseClient (singleton `supabase`)
└── Stores/                   — AuthStore, HabitsStore, AnalyticsStore, CalendarStore
```

**Pattern:** SwiftUI views observe `@StateObject`/`@EnvironmentObject` stores. Stores own all Supabase calls. Models are dumb `Codable` structs. Stores' async methods return `String?` — `nil` on success, error message on failure — and views display the string.

## Build & run

### Prerequisites

- macOS with Xcode 26+
- An iOS Simulator (project targets iPhone 17 / iOS 26.4 by default)
- A Supabase project ([sign up free](https://supabase.com))

### Setup

1. Clone the repo.
2. Open `miniHabits.xcodeproj` in Xcode.
3. Configure Supabase. The URL is hardcoded in `miniHabits/Services/Config.swift` and the anon key has an env override:
   ```bash
   export SUPABASE_ANON_KEY=<your anon key>
   ```
   Or edit `Config.swift` directly. **Never commit a service-role key.**
4. Provision the Supabase schema (tables: `habits`, `habit_logs`, `profiles`). Schema file is not yet in the repo — TODO.
5. Build & run from Xcode (⌘R), or from the CLI:
   ```bash
   xcodebuild -project miniHabits.xcodeproj -scheme miniHabits \
     -destination 'platform=iOS Simulator,name=iPhone 17' build
   ```

There is no XCTest target yet; verification is a clean build plus a manual run in the simulator.

## Roadmap

### In progress
- **Google OAuth login** — code path planned (custom URL scheme `minihabits://login-callback`), waiting on Supabase dashboard config.

### Queued
- **Home screen widgets** — show today's habits on the home screen and check them off via [AppIntent](https://developer.apple.com/documentation/appintents/) without opening the app. Needs a Widget Extension target and an App Group entitlement (`group.minhas.miniHabits`).
- **App icon** — replace placeholder with the project's "m/m/m/m" logo.
- **Schema export** — commit the Supabase migration files so a fresh clone can reproduce the backend.

### Cleanups
- Delete the unused `ContentView.swift` Xcode template leftover.
- Resolve the two warnings in `Features/Profile/ProfileView.swift` (deprecated `Text + Text` concatenation, unused `try?` result).

## Development notes

- **Imports:** SwiftUI files using `Combine` publishers must `import Combine`. Files touching Supabase types (`User.id`, `AnyJSON`) must `import Supabase`.
- **Async:** prefer Swift Concurrency; avoid mixing in Combine pipelines for new code.
- **Errors:** stores return `String?`, views display the message — don't throw across the view boundary.
- **No new dependencies** without discussion. Every SPM addition is a long-term cost.
- The repo lives on an external volume in dev (`/Volumes/MinhazStorage/...`); if the volume unmounts mid-session, the shell (and Claude Code session) will die. Always launch tools from the project root.

See [`CLAUDE.md`](./CLAUDE.md) for the AI-assisted development context: build commands, conventions, the active task notes, and queued work in more detail.

## License

Personal project — no public license. All rights reserved.
