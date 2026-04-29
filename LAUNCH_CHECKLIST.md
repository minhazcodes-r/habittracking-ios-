# HabitTracking iOS Launch Checklist

This repo is a **Swift Package** with an iOS SwiftUI executable target.

## 1) Local prerequisites

- Xcode 15+ (iOS 17 SDK)
- A valid Apple Developer Team configured in Xcode
- A Supabase project URL + anon key

## 2) Configure Supabase key

`HabitTrackingIOS/Services/Config.swift` now reads `SUPABASE_ANON_KEY` from the app process environment first.

In Xcode:
1. Open `Package.swift` in Xcode.
2. Select the `HabitTrackingIOS` run scheme.
3. **Edit Scheme** → **Run** → **Arguments** → **Environment Variables**.
4. Add: `SUPABASE_ANON_KEY=<your real anon key>`.

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
