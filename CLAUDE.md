# miniHabits — Claude project guide

iOS habit tracker. SwiftUI + Supabase backend.

## Project facts

- **Path:** `/Volumes/MinhazStorage/miniHabits2/miniHabits` — always launch Claude from here. Do not `cd` into the *other* repo at `/Volumes/MinhazStorage/miniHabits/HabitTrackingIOS`; it is stale and unrelated.
- **Xcode project:** `miniHabits.xcodeproj`, scheme `miniHabits`, bundle ID `minhas.miniHabits`
- **Deployment target:** iOS 26.4
- **Backend:** Supabase. URL is hardcoded in `miniHabits/Services/Config.swift`; anon key has an env override.
- **Auth:** Supabase email/password works. Google OAuth is the active in-progress feature (see Active task).
- **Git remote:** `git@github.com:MinhazCodes-R/HabitTracking-IOS-.git`. Default branch is `main`. Heads up: in past sessions `local main` accidentally tracked `origin/claude/relaunch-and-oauth` — verify with `git rev-parse --abbrev-ref '@{u}'` before pushing.

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

## Agentic dev flow (set up 2026-05-03)

This repo has a Claude Code agentic flow scaffolded under `.claude/` (gitignored — local only). Read this before reinventing it.

### Subagents (`.claude/agents/`)
- `ios-architect` — produces a tight implementation plan for non-trivial features (files to touch, data flow, open questions). No code.
- `swift-implementer` — executes a plan or a clear ask: edits Swift, runs `xcodebuild`, fixes errors, reports back. Will not redesign or pull in dependencies without asking.
- `ios-reviewer` — reads `git diff` and surfaces blockers / should-fix / nits. Read-only.
- `ios-builder` — runs a clean build and returns only the `error:` lines (cheap way to verify compile).

### Slash commands (`.claude/commands/`)
- `/resume` — re-orient on active task + queued work + git state. Read-only.
- `/spec <feature>` — invokes `ios-architect` to draft a plan.
- `/ship <feature-or-plan>` — chains `swift-implementer` → `ios-builder` → `ios-reviewer`. Stops on the first failure. Does not commit or push.
- `/build` — quick green/red via `ios-builder`.

### Memory: claude-mem
Globally enabled (`~/.claude/plugins/marketplaces/thedotmack/`). Worker runs on `127.0.0.1:37701`. Captures observations from each session, injects relevant context into future ones (starts on the *second* session in a project). Live viewer: `http://127.0.0.1:37701`.

If the worker isn't running: `PATH="$HOME/.bun/bin:$PATH" bunx claude-mem start`.

### Parallel agents: claude-squad
Installed as `cs` (and `claude-squad`). Each session runs in its own git worktree. Best for "queue 4 unrelated tasks before bed, review worktrees in the morning." Requires `gh auth login` for the push-to-GitHub keybinding (`s`).

### Honest note on "fully autonomous" mode

There is no autonomous loop wired up here, deliberately. Reasons:
1. Most queued work on this project is **blocked on user input** (Supabase Google config, Apple Developer signing, asset PNG, App Group entitlement). An agent can't unblock those.
2. The only autonomously-actionable items right now are the small cleanups (delete `ContentView.swift`, fix two `ProfileView.swift` warnings) — not enough to justify a runaway loop.
3. `/loop`-driven autonomous Claude on Opus runs up real bills with no human course-correction.

If a future session genuinely needs autonomous batch execution, the cleanest path is `claude-squad` with explicit task descriptions per worktree, **not** an unbounded `/loop`.

### Native-build gotcha (resolved)
`npx claude-mem install` fails on Node 24/25 due to C++20 concept errors when compiling tree-sitter against macOS libc++. Workaround used: install via Node 22 (`brew install node@22`, run install with `PATH="/opt/homebrew/opt/node@22/bin:$PATH" npx claude-mem install`). Runtime worker uses `bun`, not node, so day-to-day operation doesn't care which node is on PATH.

## Environment quirks

- This repo lives on an external volume (`/Volumes/MinhazStorage`). If the volume unmounts mid-session the shell dies — relaunch from this dir.
- A previous session's shell died because its starting cwd was a *different* (since-deleted) repo at `/Volumes/MinhazStorage/miniHabits/HabitTrackingIOS`. Always start Claude from this directory.
- Last-known booted simulator: iPhone 17 (iOS 26.4).
