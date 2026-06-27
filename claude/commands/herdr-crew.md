---
description: Launch the four CLI harnesses (claude, codex, pi, agy) on the SAME task, interactively, in a new tab of the current herdr workspace — watch and steer all four live.
argument-hint: [task every harness gets, e.g. "add a --json flag to the export command"]
---

Use the **herdr-crew** skill. Spin up the four coding **harnesses** — the CLIs
`claude`, `codex`, `pi`, and `agy` (not bare models or subagents; each drives
its own model via `CLAUDE_MODEL` / `CODEX_MODEL` / `PI_MODEL` / `AGY_MODEL`) —
each interactively with the **same** task pre-loaded, in a **new tab of the
current herdr workspace** so I never switch workspaces.

Just run the launcher from the repo I'm in:

```bash
claude/skills/herdr-crew/scripts/herdr-crew.sh "$ARGUMENTS"
```

It opens one new tab, tiles it 2×2 (claude · codex / pi · agy), launches each
harness interactively with the task, and prints the pane→harness map. Then tell
me to switch to the tab — I'll watch and steer each pane myself.

Do **not** decompose the task, capture output, judge, or create worktrees — this
is the simple, hands-on, herdr-only crew. For a scored best-of-N use `/bakeoff`;
to split a task with reviewer gating use `/orch`.

This is herdr-only: if I'm not inside a running herdr session the script will
say so — don't fall back to tmux.

$ARGUMENTS
