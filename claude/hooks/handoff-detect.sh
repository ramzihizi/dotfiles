#!/usr/bin/env bash
# SessionStart hook: if the current repo has a waiting handoff, surface it to
# the new session. Silent (exit 0, no output) when there is none, so it costs
# nothing in the common case. SessionStart stdout is added to session context.
set -euo pipefail

# We only need the project dir. Hooks run with cwd = project dir, so $PWD is the
# reliable default; refine from the stdin JSON's cwd only if jq is available.
input="$(cat 2>/dev/null || true)"
proj="$PWD"
if command -v jq >/dev/null 2>&1 && [ -n "$input" ]; then
  cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
  [ -n "$cwd" ] && proj="$cwd"
fi

handoff="$proj/.handoffs/HANDOFF.md"
[ -f "$handoff" ] || exit 0

# Extract the "▶ Resume here" section: from that heading to the next "## ".
resume="$(awk '
  /^##[[:space:]]+▶[[:space:]]+Resume here[[:space:]]*$/ { f=1; next }
  /^##[[:space:]]/ { if (f) exit }
  f { print }
' "$handoff")"

echo "📋 A session handoff is waiting in this repo."
echo "Read .handoffs/HANDOFF.md before starting — it is the previous session's state."
if [ -n "$(printf '%s' "$resume" | tr -d '[:space:]')" ]; then
  echo
  echo "▶ Resume here:"
  printf '%s\n' "$resume"
fi
exit 0
