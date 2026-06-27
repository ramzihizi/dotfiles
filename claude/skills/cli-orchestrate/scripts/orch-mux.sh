#!/usr/bin/env bash
# orch-mux.sh — multiplexer-agnostic front door for the visible orchestration
# grid. Picks tmux or herdr at call time, then execs the matching backend with
# the SAME interface (grid|run|watch <session> <args...>). The jobs-file format
# and the worker harnesses (run-worker.sh → codex|pi|agy|claude) are identical
# either way — only the "watch it live" layer differs.
#
# Usage:
#   orch-mux.sh [tmux|herdr|auto] <grid|run|watch> <session> <args...>
#
#   The leading multiplexer token is optional. If the first argument is one of
#   tmux|herdr|auto it selects the backend; otherwise the backend is chosen
#   from $ORCH_MUX (default: auto) and the first argument is the mode.
#
# Auto-detection (when mux=auto): inside tmux ($TMUX set) → tmux; inside herdr
# ($HERDR_ENV / $HERDR_PANE_ID set, or a herdr server reachable) → herdr.
#
# Examples:
#   orch-mux.sh grid orch /tmp/orch.jobs            # auto-detect current mux
#   orch-mux.sh herdr grid orch /tmp/orch.jobs      # force herdr
#   ORCH_MUX=tmux orch-mux.sh grid orch /tmp/orch.jobs
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
die() { echo "orch-mux: $*" >&2; exit 1; }

mux=${ORCH_MUX:-auto}
case "${1:-}" in
  tmux|herdr|auto) mux=$1; shift;;
esac

detect() {
  if [ -n "${TMUX:-}" ]; then echo tmux; return; fi
  if [ -n "${HERDR_ENV:-}${HERDR_PANE_ID:-}${HERDR_SOCKET_PATH:-}" ] \
     || herdr status client >/dev/null 2>&1; then echo herdr; return; fi
  # Last resort: whichever binary exists (prefer herdr — it's the current default env).
  command -v herdr >/dev/null 2>&1 && { echo herdr; return; }
  command -v tmux  >/dev/null 2>&1 && { echo tmux;  return; }
  echo none
}
[ "$mux" = auto ] && mux=$(detect)

case "$mux" in
  tmux)  exec bash "$HERE/orch-tmux.sh"  "$@";;
  herdr) exec bash "$HERE/orch-herdr.sh" "$@";;
  none)  die "no multiplexer detected — start tmux or herdr, or pass tmux|herdr explicitly";;
  *)     die "unknown multiplexer '$mux' (use: tmux | herdr | auto)";;
esac
