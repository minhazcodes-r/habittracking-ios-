#!/usr/bin/env bash
# Agent automation driver for miniHabits.
#
# Picks the first `- [ ]` task from automation/queue.md, runs `claude -p`
# headless to implement it, gates on `xcodebuild`, commits + pushes to
# agent-automation-test on green. Runs ONE task per invocation by default.
#
# Usage:
#   ./automation/loop.sh             # run the next task and exit
#   ./automation/loop.sh --watch     # drain the queue (one task at a time)
#   ./automation/loop.sh --dry-run   # show the next task without doing anything
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

BRANCH="agent-automation-test"
QUEUE="automation/queue.md"
PROMPT_TEMPLATE="automation/prompts/task-prompt.md"
LOG_DIR="automation/logs"
MAX_TURNS="${MAX_TURNS:-30}"
SCHEME="miniHabits"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

mkdir -p "$LOG_DIR"

command -v claude    >/dev/null || { echo "claude CLI not on PATH. Install Claude Code first." >&2; exit 1; }
command -v xcodebuild >/dev/null || { echo "xcodebuild not on PATH. Install Xcode command line tools." >&2; exit 1; }

current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
  echo "Refusing to run on $current_branch. Switch to $BRANCH first." >&2
  exit 1
fi
if [[ "$current_branch" != "$BRANCH" ]]; then
  echo "On '$current_branch', not '$BRANCH'. Proceed anyway? [y/N]"
  read -r ans
  [[ "$ans" == "y" || "$ans" == "Y" ]] || exit 1
fi

pick_next_task() {
  grep -n '^- \[ \] ' "$QUEUE" | head -1 || true
}

run_one() {
  local task_line task_lineno task_text stamp log prompt
  task_line=$(pick_next_task)
  if [[ -z "$task_line" ]]; then
    echo "Queue empty."
    return 1
  fi
  task_lineno="${task_line%%:*}"
  task_text="${task_line#*:- \[ \] }"

  stamp=$(date +%Y%m%d-%H%M%S)
  log="$LOG_DIR/$stamp.log"
  echo "task: $task_text"
  echo "log:  $log"

  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree dirty. Commit or stash before running." >&2
    return 1
  fi

  prompt=$(sed "s|{{TASK}}|$task_text|g" "$PROMPT_TEMPLATE")

  if ! claude -p "$prompt" \
       --permission-mode bypassPermissions \
       --max-turns "$MAX_TURNS" 2>&1 | tee "$log"; then
    echo "Claude run errored. Reverting." >&2
    git reset --hard HEAD
    return 1
  fi

  echo "Building..."
  if ! xcodebuild -project miniHabits.xcodeproj -scheme "$SCHEME" \
        -destination "$DESTINATION" -quiet build >>"$log" 2>&1; then
    echo "Build failed. Reverting. See $log" >&2
    git reset --hard HEAD
    return 1
  fi

  if git diff --quiet && git diff --cached --quiet; then
    echo "No file changes — Claude declined or no-op'd. Marking done anyway."
  fi

  sed -i '' "${task_lineno}s|- \[ \] |- [x] |" "$QUEUE"

  git add -A
  git commit -m "agent: $task_text

Automated by automation/loop.sh
Turns capped at $MAX_TURNS, gated on xcodebuild $SCHEME Debug
Log: $log"

  git push -u origin "$BRANCH"
  echo "Pushed: $task_text"
  return 0
}

case "${1:-}" in
  --dry-run)
    line=$(pick_next_task)
    [[ -z "$line" ]] && echo "(queue empty)" || echo "$line"
    ;;
  --watch)
    while run_one; do echo "---- next ----"; done
    ;;
  *)
    run_one
    ;;
esac
