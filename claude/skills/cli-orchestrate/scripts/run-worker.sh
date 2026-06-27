#!/usr/bin/env bash
# run-worker.sh — dispatch one task to a heterogeneous agent CLI worker.
#
# Usage:
#   run-worker.sh <backend> <workdir> <prompt-file> <out-file> [mode]
#
#   backend    codex | pi | agy | claude
#   workdir    directory the worker runs in (usually a git worktree)
#   prompt-file path to a file containing the task prompt
#   out-file   where the worker's final answer is written
#   mode       work (default, may edit files) | review (read-only second opinion)
#
# Model overrides via env: CODEX_MODEL, PI_MODEL, AGY_MODEL, CLAUDE_MODEL
# (claude backend = headless `claude -p`, so a Claude leg is a visible tmux pane like the rest)
# Per-worker timeout (seconds) via WORKER_TIMEOUT (default 1200).
#
# Exit code is the worker's exit code. Full transcript goes to stderr/out-file;
# the conductor reads <out-file> for the distilled result.
set -uo pipefail

backend=${1:?backend required: codex|pi|agy|claude}
workdir=${2:?workdir required}
promptfile=${3:?prompt-file required}
outfile=${4:?out-file required}
mode=${5:-work}
timeout_s=${WORKER_TIMEOUT:-1200}

[ -d "$workdir" ] || { echo "run-worker: workdir not found: $workdir" >&2; exit 2; }
[ -f "$promptfile" ] || { echo "run-worker: prompt-file not found: $promptfile" >&2; exit 2; }
prompt=$(cat "$promptfile")
: > "$outfile"

# Portable timeout wrapper (macOS lacks GNU timeout unless coreutils installed).
runtimeout() {
  if command -v timeout >/dev/null 2>&1; then timeout "$timeout_s" "$@";
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$timeout_s" "$@";
  else "$@"; fi
}

echo "▶ $backend ($mode) in $workdir" >&2

case "$backend" in
  codex)
    sandbox="workspace-write"; [ "$mode" = review ] && sandbox="read-only"
    if [ "$mode" = review ]; then
      ( cd "$workdir" && runtimeout codex exec review \
          ${CODEX_MODEL:+-m "$CODEX_MODEL"} \
          --skip-git-repo-check "$prompt" ) >"$outfile" 2>&2
    else
      ( cd "$workdir" && runtimeout codex exec \
          -s "$sandbox" --skip-git-repo-check \
          ${CODEX_MODEL:+-m "$CODEX_MODEL"} \
          -o "$outfile" "$prompt" ) >&2
    fi
    ;;
  pi)
    # pi has no --cd; runs in cwd. --no-session = ephemeral, -a trusts project files.
    ( cd "$workdir" && runtimeout pi -p --no-session -a \
        ${PI_MODEL:+--model "$PI_MODEL"} \
        ${PI_PROVIDER:+--provider "$PI_PROVIDER"} \
        "$prompt" ) >"$outfile" 2>&2
    ;;
  agy)
    # agy = the new agent harness (replaces opencode). Claude-Code-style CLI:
    # --print runs one prompt headless. work mode auto-approves writes; review
    # mode omits that flag so it stays read-only. --print-timeout matches the
    # worker timeout so agy doesn't self-abort at its 5m default on long runs.
    extra=""; [ "$mode" = work ] && extra="--dangerously-skip-permissions"
    ( cd "$workdir" && runtimeout agy --print $extra \
        --print-timeout "${timeout_s}s" \
        ${AGY_MODEL:+--model "$AGY_MODEL"} \
        "$prompt" ) >"$outfile" 2>&2
    ;;
  claude)
    # headless Claude Code, read-only by design — the visible-pane Claude *critic/reviewer*
    # leg of the panel. No file-writing flag: keep work-mode edits in the conductor or a
    # supervised session, not an unattended `--dangerously-skip-permissions` agent.
    if [ "$mode" = work ]; then
      echo "run-worker: claude backend is review-only here; route file-writing legs to codex/pi/agy or the conductor's own Agent tool" >&2
      exit 2
    fi
    ( cd "$workdir" && runtimeout claude -p \
        ${CLAUDE_MODEL:+--model "$CLAUDE_MODEL"} \
        "$prompt" ) >"$outfile" 2>&2
    ;;
  *)
    echo "run-worker: unknown backend '$backend'" >&2; exit 2;;
esac
rc=$?
echo "✔ $backend exited $rc → $outfile ($(wc -l <"$outfile" | tr -d ' ') lines)" >&2
exit $rc
