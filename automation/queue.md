# Agent automation queue

Each line under **Pending** is one autonomous task. The driver
(`automation/loop.sh`) picks the first `- [ ]` line, runs Claude on it, gates
on a clean build, then commits + pushes to `agent-automation-test`.

## Rules for queueing

- **One concrete, verifiable change per line.** Don't bundle.
- **No tasks blocked on user input.** Skip anything that needs Supabase
  dashboard config, Apple signing changes, App Group entitlements, or new
  asset PNGs. Those are listed under *Blocked* below for visibility only.
- The line text becomes the commit subject — write it like a TODO, not a
  paragraph.

## Pending

- [ ] Delete the unused `miniHabits/ContentView.swift` Xcode template leftover and remove any project references to it.
- [ ] Fix the deprecated `Text + Text` concatenation warning in `miniHabits/Features/Profile/ProfileView.swift` around line 93 by using a single `Text` with attributed-string interpolation or an `HStack`.
- [ ] Fix the unused `try?` result warning in `miniHabits/Features/Profile/ProfileView.swift` around line 115 by assigning to `_` or handling the result.
- [ ] Add a top-level README section titled "Running the agent automation pipeline" linking to `automation/README.md`.

## Done

(driver toggles `[x]` in place — completed items stay listed for audit)

## Blocked (do not queue here — listed for tracking)

- Google OAuth wiring — Supabase provider must be enabled in the dashboard first.
- Home screen widgets — Widget Extension target + App Group entitlement (`group.minhas.miniHabits`) must be added in Xcode manually.
- App icon swap — needs the 1024×1024 PNG asset.
- Supabase schema export — the migration files need to be committed; requires the user's local Supabase project state.
