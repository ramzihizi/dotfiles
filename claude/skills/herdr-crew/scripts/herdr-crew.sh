#!/usr/bin/env bash
# herdr-crew.sh — open a new tab in the CURRENT herdr workspace, tile it 2x2,
# and launch the four CLI HARNESSES (claude, codex, pi, agy) interactively with
# the same task pre-loaded, each in AUTO + READ-ONLY mode: they run without
# stopping for approvals, but cannot write/modify the tree — so all four can
# share one working tree without colliding. Best of both worlds: hands-off, but
# safe. Watch and steer all four live; nothing is captured or auto-judged.
# herdr-only, no tmux, no worktrees, no out-files.
#
# Usage: herdr-crew.sh <task…>
#
# These are the harness CLIs, not bare models — each drives whatever model it is
# pointed at. Override per harness before launching:
#   CLAUDE_MODEL · CODEX_MODEL · PI_MODEL (+ PI_PROVIDER) · AGY_MODEL
#
# Layout (one new tab, same workspace, same repo $PWD):
#   ┌────────────┬────────────┐
#   │ claude     │ codex      │
#   ├────────────┼────────────┤
#   │ pi         │ agy        │
#   └────────────┴────────────┘
set -uo pipefail

die() { echo "herdr-crew: $*" >&2; exit 1; }
command -v herdr >/dev/null 2>&1 || die "herdr not installed"
command -v jq    >/dev/null 2>&1 || die "jq not installed (needed to parse herdr's JSON)"

task="$*"
[ -n "${task// /}" ] || die "usage: herdr-crew.sh <task…>  (the task every harness gets)"

# Current workspace: prefer the env herdr sets inside each pane, else ask the
# server which pane we're in. Either way we never switch/create a workspace.
ws="${HERDR_WORKSPACE_ID:-}"
[ -n "$ws" ] || ws=$(herdr pane current 2>/dev/null | jq -r '.result.pane.workspace_id // empty')
[ -n "$ws" ] || die "not inside a herdr pane — run this from within herdr"

short=$(printf '%s' "$task" | tr '\n' ' ' | cut -c1-40)

# New tab in the CURRENT workspace, in this repo, focused. herdr returns the
# tab's root pane and id; we split it into a fixed 2x2 grid.
created=$(herdr tab create --workspace "$ws" --cwd "$PWD" --label "crew: $short" --focus)
root=$(printf '%s' "$created" | jq -r '.result.root_pane.pane_id // empty')
tab=$( printf '%s' "$created" | jq -r '.result.tab.tab_id // empty')
[ -n "$root" ] && [ -n "$tab" ] || die "tab create failed"

# `herdr pane split` occasionally creates the pane but returns an empty result
# (a transient race), so trusting its return value can drop a pane — and a retry
# would double-create. Instead, split once and DISCOVER the new pane by diffing
# the tab's pane set before vs after. Each call captures `before` itself, so it
# needs no cross-call state (new_pane runs in a $() subshell, where a shared
# accumulator would be lost). bash-3.2 safe — no associative arrays.
panes_in_tab() { herdr pane list --workspace "$ws" | jq -r --arg t "$tab" '.result.panes[]|select(.tab_id==$t)|.pane_id'; }
new_pane() { # parent direction -> id of the pane this split created
  local parent=$1 dir=$2 before id t
  before=" $(panes_in_tab | tr '\n' ' ') "
  herdr pane split "$parent" --direction "$dir" --no-focus >/dev/null 2>&1
  for t in 1 2 3 4 5 6 7 8 9 10; do
    while read -r id; do
      case "$before" in *" $id "*) ;; *) [ -n "$id" ] && { printf '%s' "$id"; return 0; };; esac
    done < <(panes_in_tab)
    sleep 0.2
  done
  return 1
}

p1="$root"
p2=$(new_pane "$p1" right) || die "split failed (top-right pane)"
p3=$(new_pane "$p1" down)  || die "split failed (bottom-left pane)"
p4=$(new_pane "$p2" down)  || die "split failed (bottom-right pane)"

LAUNCH=$(mktemp -d "${TMPDIR:-/tmp}/herdr-crew.XXXXXX") || die "mktemp failed"

# Launch one harness in a pane: write a %q-quoted launcher (robust against any
# quotes/spaces in the task), label the pane, then run it in that pane's shell.
# The harness takes over the pane's tty → fully interactive; on exit the pane
# drops back to a normal shell prompt (herdr panes persist).
launch() { # pane label cmd args...
  local pane=$1 label=$2; shift 2
  local f="$LAUNCH/$label.sh"
  { printf '#!/usr/bin/env bash\nexec'; printf ' %q' "$@"; printf '\n'; } > "$f"
  herdr pane rename "$pane" "$label" >/dev/null 2>&1 || true
  herdr pane run "$pane" "bash $f" >/dev/null
}

# Read-only preamble prepended to the task, so each harness frames its output as
# analysis and doesn't try to edit. This is belt-and-suspenders with the
# per-harness read-only flags below — and it's the PRIMARY guard for agy, which
# has no read-only/plan flag of its own.
ro_preamble="You are running in READ-ONLY mode. You may read, search, and \
analyze any files in this repository, but you MUST NOT create, edit, move, or \
delete files, and MUST NOT run commands that change state. Deliver your findings \
and concrete recommendations as a written report only — do not apply changes."
task_ro="${ro_preamble}

Task: ${task}"

# Auto + read-only invocation per harness (plus optional model override):
#   claude  dontAsk + write tools denied  reads freely, never prompts, no write
#                                         tools — just reports. NOT plan mode:
#                                         plan mode gates on an "exit plan mode
#                                         to proceed" prompt that reads as "switch
#                                         to auto" instead of giving a result.
#                                         Bash is denied too, since dontAsk would
#                                         otherwise auto-approve a shell write
#                                         (claude has no read-only fs sandbox);
#                                         Read/Grep/Glob cover read-only review.
#   codex   -s read-only -a never         read-only sandbox; never asks
#   pi      --tools read,grep,find,ls     only read-only tools enabled
#   agy     (no read-only flag)           launched WITHOUT --dangerously-skip-
#                                         permissions, so it can't auto-write — a
#                                         write attempt pauses for you to deny.
launch "$p1" claude claude --permission-mode dontAsk --disallowedTools "Edit Write MultiEdit NotebookEdit Bash" ${CLAUDE_MODEL:+--model "$CLAUDE_MODEL"} "$task_ro"
launch "$p2" codex  codex  -s read-only -a never ${CODEX_MODEL:+-m "$CODEX_MODEL"} "$task_ro"
launch "$p3" pi     pi     --tools read,grep,find,ls -a ${PI_MODEL:+--model "$PI_MODEL"} ${PI_PROVIDER:+--provider "$PI_PROVIDER"} "$task_ro"
launch "$p4" agy    agy -i ${AGY_MODEL:+--model "$AGY_MODEL"} "$task_ro"

echo "▶ herdr-crew: new tab 'crew: $short' in workspace $ws — 4 harnesses, same task, AUTO + READ-ONLY:"
echo "    claude (top-left) · codex (top-right) · pi (bottom-left) · agy (bottom-right)"
echo "  They run hands-off but can't modify $PWD (claude/codex/pi are hard read-only;"
echo "  agy is instructed read-only and will pause rather than auto-write). Switch to"
echo "  the tab to watch; nothing is captured or judged."
