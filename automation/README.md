# Agent automation pipeline

Bounded driver that lets Claude Code work through a queue of small,
autonomously-actionable tasks on the miniHabits iOS repo and push the results
to the `agent-automation-test` branch for review.

## What one iteration does

1. Reads the first `- [ ]` line from `queue.md`.
2. Verifies the working tree is clean and we're on `agent-automation-test`.
3. Invokes `claude -p` headless with the task prompt, bounded to `MAX_TURNS=30`.
4. Runs `xcodebuild` as a gate. On failure, hard-resets and exits.
5. On green: marks the task `- [x]`, commits `agent: <task>`, pushes the branch.

The driver runs **one task per invocation** and exits. Use `--watch` to drain
the queue.

## Run it

```bash
# clean tree, on agent-automation-test branch
./automation/loop.sh             # one task
./automation/loop.sh --watch     # until queue empty
./automation/loop.sh --dry-run   # show the next task without doing it
```

Env knobs:

| Var | Default | Purpose |
|---|---|---|
| `MAX_TURNS` | `30` | Hard cap on Claude turns per task |
| `DESTINATION` | `platform=iOS Simulator,name=iPhone 17` | xcodebuild destination |

## Adding tasks

Append `- [ ]` lines to `queue.md`. Each line must be a single, verifiable
change. Lines that need Supabase dashboard config, Apple signing changes,
App Group entitlements, or new asset PNGs are listed under **Blocked** in the
queue and must not be moved into **Pending** without user action first.

## Why bounded, not a daemon

Per `../CLAUDE.md` ("Honest note on fully autonomous mode"):

1. Most miniHabits work is blocked on user input.
2. The autonomously-actionable surface is small.
3. Opus through `/loop` costs real money with no human checkpoint.

The driver runs one task per invocation so the cadence is up to you. If you
want it on a schedule, wrap it in `launchd` or `cron` yourself — keep the
bound explicit.

## Safety

- Refuses to run on `main` or `master`.
- Hard-resets the working tree on any Claude error or build failure.
- Pushes only to `agent-automation-test`.
- Each run logs to `automation/logs/<timestamp>.log` (gitignored).
- The Claude run uses `--permission-mode bypassPermissions` — required for
  non-interactive Bash, but it means Claude can run any shell command without
  prompting. The prompt template restricts behaviour, but the permission mode
  itself is the trust boundary. Don't extend `MAX_TURNS` blindly.

## Known limits

- The build gate runs `Debug`; a green Debug does not guarantee a green
  Release.
- There's no XCTest target, so "green" means "compiles" — not "behaves
  correctly". Visual / behavioural verification still needs the simulator.
- A task that needs more than `MAX_TURNS` turns will exit mid-flight. Raise
  the cap or split the task.
- The driver does not unblock itself if `claude` prompts unexpectedly — if you
  see it hang, kill it and reduce the task scope.
