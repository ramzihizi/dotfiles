#!/usr/bin/env bash
# orch-tmux.sh — give the heterogeneous multi-agent flow a visible, pre-named
# tmux session so you can watch each worker work live.
#
# Three modes:
#
#   orch-tmux.sh grid  <session> <jobs-file>     # one tiled PANE per worker, all LIVE, side by side  ← default for /orch
#   orch-tmux.sh run   <session> <jobs-file>     # one WINDOW per worker, runs it LIVE (flip with Ctrl-b w)
#   orch-tmux.sh watch <session> <out-file>...   # one pane per out-file, tail -F (watch outputs only)
#
# grid is the one you want when you're driving /orch and want to SEE every agent at once:
# each pane streams that worker's progress, then prints its final answer, then stays open.
#
# jobs-file: one job per line, pipe-separated, '#'/blank lines ignored:
#   label|backend|workdir|prompt-file|out-file|mode
#   e.g.  critique-codex|codex|.|/tmp/crit.prompt|/tmp/codex.out|review
#         critique-claude|claude|.|/tmp/crit.prompt|/tmp/claude.out|review
#
# After launch it prints the attach command (and attaches if stdout is a TTY).
# Re-running with an existing session name is refused — pick a new name or
# `tmux kill-session -t <session>` first.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$HERE/run-worker.sh"

die() { echo "orch-tmux: $*" >&2; exit 1; }
command -v tmux >/dev/null 2>&1 || die "tmux not installed"

mode=${1:-}; session=${2:-}
[ -n "$mode" ] && [ -n "$session" ] || die "usage: orch-tmux.sh grid|run|watch <session> ..."
tmux has-session -t "$session" 2>/dev/null && die "session '$session' already exists — kill it or pick another name"

attach_hint() {
  echo "▶ tmux session '$session' ready."
  echo "  watch:  tmux attach -t $session     (detach: Ctrl-b d)"
  echo "  kill:   tmux kill-session -t $session"
  if [ -t 1 ]; then exec tmux attach -t "$session"; fi
}

case "$mode" in
  grid)
    jobs=${3:?jobs-file required}
    [ -f "$jobs" ] || die "jobs-file not found: $jobs"
    first=1
    while IFS='|' read -r label backend workdir promptf outf jmode; do
      case "$label" in ''|\#*) continue;; esac
      jmode=${jmode:-work}
      # Each pane: stream the worker's live progress, then print its final answer, then stay open.
      cmd="echo '=== $label : $backend ($jmode) — running, live ==='; bash '$RUNNER' '$backend' '$workdir' '$promptf' '$outf' '$jmode'; ec=\$?; echo; echo '=== $label · answer (exit '\$ec') ==='; cat '$outf' 2>/dev/null; echo; echo '--- done · pane stays open (Ctrl-b z to zoom) ---'; exec \$SHELL"
      if [ $first -eq 1 ]; then
        tmux new-session -d -s "$session" -n agents "$cmd"; first=0
      else
        tmux split-window -t "$session" "$cmd"
        tmux select-layout -t "$session" tiled >/dev/null
      fi
    done < "$jobs"
    [ $first -eq 0 ] || die "no valid jobs parsed from $jobs"
    tmux select-layout -t "$session" tiled >/dev/null
    tmux set-option -t "$session" pane-border-status top >/dev/null 2>&1 || true
    attach_hint
    ;;
  run)
    jobs=${3:?jobs-file required}
    [ -f "$jobs" ] || die "jobs-file not found: $jobs"
    first=1
    while IFS='|' read -r label backend workdir promptf outf jmode; do
      case "$label" in ''|\#*) continue;; esac
      jmode=${jmode:-work}
      # Keep the pane open after the worker exits so you can read the result.
      cmd="echo '=== $label : $backend ($jmode) ==='; bash '$RUNNER' '$backend' '$workdir' '$promptf' '$outf' '$jmode'; echo; echo '--- done (exit '\$?') · pane stays open ---'; exec \$SHELL"
      if [ $first -eq 1 ]; then
        tmux new-session -d -s "$session" -n "$label" "$cmd"; first=0
      else
        tmux new-window -t "$session" -n "$label" "$cmd"
      fi
    done < "$jobs"
    [ $first -eq 0 ] || die "no valid jobs parsed from $jobs"
    tmux select-window -t "$session:0"
    attach_hint
    ;;
  watch)
    shift 2
    [ $# -ge 1 ] || die "watch needs at least one out-file"
    tmux new-session -d -s "$session" -n watch "echo 'waiting for $1'; touch '$1' 2>/dev/null; tail -F '$1'"
    shift
    for f in "$@"; do
      tmux split-window -t "$session" "echo 'waiting for $f'; touch '$f' 2>/dev/null; tail -F '$f'"
      tmux select-layout -t "$session" tiled >/dev/null
    done
    attach_hint
    ;;
  *) die "unknown mode '$mode' (use: grid | run | watch)";;
esac
