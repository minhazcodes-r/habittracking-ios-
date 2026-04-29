# HabitTracking iOS Launch Checklist

This repo is a **Swift Package** with an iOS SwiftUI executable target.

## 1) Local prerequisites

- Xcode 15+ (iOS 17 SDK)
- A valid Apple Developer Team configured in Xcode
- A Supabase project URL + anon key

## 2) Configure Supabase key

`HabitTrackingIOS/Services/Config.swift` now reads `SUPABASE_ANON_KEY` (or `SUPABASE_KEY`) from the app process environment first.

In Xcode:
1. Open `Package.swift` in Xcode.
2. Select the `HabitTrackingIOS` run scheme.
3. **Edit Scheme** → **Run** → **Arguments** → **Environment Variables**.
4. Add: `SUPABASE_ANON_KEY=<your real anon key>` (or `SUPABASE_KEY`).

## 3) Resolve dependencies

From repo root:

```bash
swift package resolve
```

If your network/proxy blocks GitHub, use one of:
- Corporate proxy allowlist for `github.com`.
- A local package mirror.
- Xcode on a machine with unrestricted outbound network.

## 4) Build and run from Xcode (recommended for launch)

1. Open `Package.swift` in Xcode.
2. Pick an iOS Simulator (or connected device).
3. Product → Build.
4. Product → Run.

## 5) Release-readiness checks

- Replace placeholder key usage in all schemes.
- Verify sign-in/sign-up flows against production Supabase.
- Add App Icons + launch screen assets if still missing.
- Archive from Xcode and validate before App Store upload.

## 6) If run pauses with `BUNDLE_IDENTIFIER_FOR_CURRENT_PROCESS_IS_NIL`

This is usually an Xcode run configuration issue (not a Swift compile failure).

### Symptoms
- Xcode pauses in assembly.
- Thread shows: `com.apple.uikit.eventfetch-thread: EXC_BREAKPOINT`.
- Symbol includes: `BUNDLE_IDENTIFIER_FOR_CURRENT_PROCESS_IS_NIL`.

### Fix
1. In Xcode, click the package app target (`HabitTrackingIOS`) and open **Build Settings**.
2. Set **Product Bundle Identifier** to a real value, e.g. `com.yourcompany.minihabits`.
3. Open **Signing & Capabilities** and choose your Team for the active scheme.
4. Clean build folder (**Shift+Cmd+K**) and run again.
5. If it still pauses, disable an "All Exceptions" breakpoint temporarily and confirm whether the app actually keeps running.

## 7) Fastest path to run on Simulator (ASAP)

1. Open `Package.swift` in Xcode and wait for package indexing to complete.
2. Set **Product Bundle Identifier** to a unique value (example: `com.yourname.minihabits`).
3. In **Signing & Capabilities**, pick your Apple team (Personal Team is fine for simulator testing).
4. Edit Scheme → Run → Environment Variables:
   - `SUPABASE_ANON_KEY=<real anon key>`
5. Select `iPhone 17` (or any simulator), then press **⌘R**.
6. If paused in assembly, continue once (**⌃⌘Y**) and verify whether app UI appears.
7. If app does not launch, clean and retry:
   - Product → Clean Build Folder (**⇧⌘K**)
   - Delete Derived Data for this project
   - Run again (**⌘R**)
