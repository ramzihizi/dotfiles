#!/usr/bin/env bash
# orch-herdr.sh — herdr-native sibling of orch-tmux.sh. Gives the heterogeneous
# multi-agent flow a visible, pre-named herdr WORKSPACE so you can watch each
# worker work live, exactly like the tmux grid — just driven through herdr's
# socket-API CLI (`herdr workspace|tab|pane …`) instead of tmux.
#
# Same three modes and same jobs-file format as orch-tmux.sh, so the conductor
# and the slash commands can target either multiplexer through orch-mux.sh:
#
#   orch-herdr.sh grid  <session> <jobs-file>     # one tiled PANE per worker in one workspace  ← default
#   orch-herdr.sh run   <session> <jobs-file>     # one TAB per worker in one workspace
#   orch-herdr.sh watch <session> <out-file>...   # one pane per out-file, tail -F (outputs only)
#
# jobs-file: one job per line, pipe-separated, '#'/blank lines ignored:
#   label|backend|workdir|prompt-file|out-file|mode
#   e.g.  critique-codex|codex|.|/tmp/crit.prompt|/tmp/codex.out|review
#
# The "session" is a herdr workspace labelled <session>. Re-using a live label is
# refused — pick a new name or `herdr workspace close <id>` first. herdr panes
# persist after their command exits (they drop back to a shell), so unlike the
# tmux version there is no `exec $SHELL` tail.
set -uo pipefail

RUNNER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/run-worker.sh"

die() { echo "orch-herdr: $*" >&2; exit 1; }
command -v herdr >/dev/null 2>&1 || die "herdr not installed"
command -v jq    >/dev/null 2>&1 || die "jq not installed (needed to parse herdr's JSON)"
[ -n "${HERDR_ENV:-}${HERDR_SOCKET_PATH:-}" ] || herdr status client >/dev/null 2>&1 \
  || die "no running herdr server reachable — launch herdr first"

mode=${1:-}; session=${2:-}
[ -n "$mode" ] && [ -n "$session" ] || die "usage: orch-herdr.sh grid|run|watch <session> ..."

# herdr allows duplicate workspace labels; mirror tmux's has-session guard so a
# re-run doesn't silently stack a second '<session>' workspace.
existing=$(herdr workspace list 2>/dev/null \
  | jq -r --arg l "$session" '.result.workspaces[] | select(.label==$l) | .workspace_id' | head -1)
[ -z "$existing" ] || die "workspace '$session' already exists ($existing) — close it or pick another name"

# Scratch dir for per-pane launcher scripts. Passing the compound command as a
# file (herdr pane run '<id>' 'bash <file>') sidesteps all nested-quote hazards
# of sending a long ';'-joined command line through the socket CLI.
LAUNCH_DIR=$(mktemp -d "${TMPDIR:-/tmp}/orch-herdr.XXXXXX") || die "mktemp failed"

ws_create() { herdr workspace create --label "$session" --no-focus | jq -r '.result.workspace.workspace_id'; }
ws_root()   { herdr workspace get "$1" >/dev/null 2>&1; herdr pane list --workspace "$1" | jq -r '.result.panes[0].pane_id'; }
split()     { herdr pane split "$1" --direction "$2" --no-focus | jq -r '.result.pane.pane_id'; }
tab_root()  { herdr tab create --workspace "$1" --label "$2" --no-focus | jq -r '.result.root_pane.pane_id'; }

# Build an ~even grid of N panes in one tab and echo their pane ids in order.
# Columns first (split right), then rows within each column (split down) — a
# balanced BSP that reads like tmux's `select-layout tiled` for small N.
build_grid() {
  local root=$1 n=$2 cols rows_base extra c r p count
  cols=$(awk -v n="$n" 'BEGIN{c=int(sqrt(n)); if(c*c<n)c++; if(c<1)c=1; print c}')
  rows_base=$(( n / cols )); extra=$(( n % cols ))
  local -a col_panes=( "$root" )
  for (( c=1; c<cols; c++ )); do col_panes[c]=$(split "${col_panes[c-1]}" right); done
  for (( c=0; c<cols; c++ )); do
    count=$rows_base; [ "$c" -lt "$extra" ] && count=$(( rows_base + 1 ))
    p=${col_panes[c]}; echo "$p"
    for (( r=1; r<count; r++ )); do p=$(split "$p" down); echo "$p"; done
  done
}

# Compose the live-pane command for one job and stash it as a launcher script.
# Mirrors orch-tmux.sh's grid pane: banner → run worker → print the captured
# answer → leave the pane on a shell prompt.
launcher() { # label backend workdir promptf outf jmode -> path
  local label=$1 backend=$2 workdir=$3 promptf=$4 outf=$5 jmode=$6
  local f="$LAUNCH_DIR/${label//[^A-Za-z0-9_-]/_}.sh"
  {
    printf '%s\n' "#!/usr/bin/env bash"
    printf 'echo "=== %s : %s (%s) — running, live ==="\n' "$label" "$backend" "$jmode"
    printf 'bash %q %q %q %q %q %q\n' "$RUNNER" "$backend" "$workdir" "$promptf" "$outf" "$jmode"
    printf 'ec=$?\n'
    printf 'echo; echo "=== %s · answer (exit $ec) ==="\n' "$label"
    printf 'cat %q 2>/dev/null\n' "$outf"
    printf 'echo; echo "--- done · pane stays open (this is a normal shell) ---"\n'
  } > "$f"
  echo "$f"
}

read_jobs() { # populate LABELS/BACKENDS/WORKDIRS/PROMPTS/OUTS/MODES from a jobs-file
  local jobs=$1 label backend workdir promptf outf jmode
  [ -f "$jobs" ] || die "jobs-file not found: $jobs"
  LABELS=(); BACKENDS=(); WORKDIRS=(); PROMPTS=(); OUTS=(); MODES=()
  while IFS='|' read -r label backend workdir promptf outf jmode; do
    case "$label" in ''|\#*) continue;; esac
    LABELS+=("$label"); BACKENDS+=("$backend"); WORKDIRS+=("${workdir:-.}")
    PROMPTS+=("$promptf"); OUTS+=("$outf"); MODES+=("${jmode:-work}")
  done < "$jobs"
  [ "${#LABELS[@]}" -gt 0 ] || die "no valid jobs parsed from $jobs"
}

attach_hint() { # workspace_id
  echo "▶ herdr workspace '$session' ready ($1)."
  echo "  watch:  herdr workspace focus $1        (or the prefix+w picker)"
  echo "  close:  herdr workspace close $1"
}

case "$mode" in
  grid)
    read_jobs "${3:?jobs-file required}"
    ws=$(ws_create); [ -n "$ws" ] || die "workspace create failed"
    mapfile -t PANES < <(build_grid "$(ws_root "$ws")" "${#LABELS[@]}")
    for i in "${!LABELS[@]}"; do
      f=$(launcher "${LABELS[i]}" "${BACKENDS[i]}" "${WORKDIRS[i]}" "${PROMPTS[i]}" "${OUTS[i]}" "${MODES[i]}")
      herdr pane rename "${PANES[i]}" "${LABELS[i]}" >/dev/null 2>&1 || true
      herdr pane run "${PANES[i]}" "bash $f" >/dev/null
    done
    attach_hint "$ws"
    ;;
  run)
    read_jobs "${3:?jobs-file required}"
    ws=$(ws_create); [ -n "$ws" ] || die "workspace create failed"
    for i in "${!LABELS[@]}"; do
      if [ "$i" -eq 0 ]; then pane=$(ws_root "$ws"); herdr tab rename "$(herdr pane get "$pane" | jq -r '.result.pane.tab_id')" "${LABELS[0]}" >/dev/null 2>&1 || true
      else pane=$(tab_root "$ws" "${LABELS[i]}"); fi
      f=$(launcher "${LABELS[i]}" "${BACKENDS[i]}" "${WORKDIRS[i]}" "${PROMPTS[i]}" "${OUTS[i]}" "${MODES[i]}")
      herdr pane rename "$pane" "${LABELS[i]}" >/dev/null 2>&1 || true
      herdr pane run "$pane" "bash $f" >/dev/null
    done
    attach_hint "$ws"
    ;;
  watch)
    shift 2
    [ $# -ge 1 ] || die "watch needs at least one out-file"
    files=( "$@" )
    ws=$(ws_create); [ -n "$ws" ] || die "workspace create failed"
    mapfile -t PANES < <(build_grid "$(ws_root "$ws")" "${#files[@]}")
    for i in "${!files[@]}"; do
      f="$LAUNCH_DIR/watch_$i.sh"
      printf '#!/usr/bin/env bash\necho "waiting for %s"\ntouch %q 2>/dev/null\ntail -F %q\n' \
        "${files[i]}" "${files[i]}" "${files[i]}" > "$f"
      herdr pane rename "${PANES[i]}" "$(basename "${files[i]}")" >/dev/null 2>&1 || true
      herdr pane run "${PANES[i]}" "bash $f" >/dev/null
    done
    attach_hint "$ws"
    ;;
  *) die "unknown mode '$mode' (use: grid | run | watch)";;
esac
