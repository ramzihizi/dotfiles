---
name: herdr-crew
description: Use when the user wants to spin up the four CLI harnesses (claude, codex, pi, agy) side by side on the SAME task, interactively, in a new tab of the CURRENT herdr workspace — to watch and steer all four live. herdr-only, no judging/worktrees. Triggers - "herdr-crew", "the crew", "all four harnesses on this", "quad harness", "open the crew on X".
---

# herdr-crew — four harnesses, one tab, current workspace

Spin up the four coding **harnesses** — `claude`, `codex`, `pi`, `agy` — each in
its own pane, all in a **new tab of the current herdr workspace**, each launched
**interactively with the same task pre-loaded**. You watch all four work side by
side and steer any pane directly. Nothing is captured, scored, or auto-judged —
this is the deliberately-simple, herdr-native cousin of `/bakeoff`.

## Harnesses, not agents

The four panes run the **harness CLIs themselves**, not bare models or
subagents. Each harness drives whatever model it is pointed at; override per
harness before launching:

| Harness  | Pane         | Interactive launch | Model override               |
| -------- | ------------ | ------------------ | ---------------------------- |
| `claude` | top-left     | `claude "<task>"`  | `CLAUDE_MODEL`               |
| `codex`  | top-right    | `codex "<task>"`   | `CODEX_MODEL`                |
| `pi`     | bottom-left  | `pi "<task>"`      | `PI_MODEL` (+ `PI_PROVIDER`) |
| `agy`    | bottom-right | `agy -i "<task>"`  | `AGY_MODEL`                  |

When the user says "the crew" / "all four harnesses", they mean these four CLIs.

## When to use

- You want a quick, heterogeneous, **hands-on** take from all four harnesses on
  one task, without leaving the current herdr workspace.
- You'll watch and steer each pane yourself — no headless capture or judging.

For a scored best-of-N with worktree isolation and a judge pass, use `/bakeoff`
instead. To decompose a task across harnesses with reviewer gating, use `/orch`.

## How to run it

```bash
claude/skills/herdr-crew/scripts/herdr-crew.sh "<the task every harness gets>"
```

The script (run from the repo you want them working in):

1. Finds the **current** workspace from `$HERDR_WORKSPACE_ID` (no switch, no new
   workspace).
2. `herdr tab create` — a new tab in that workspace, `--cwd $PWD`, focused.
3. Splits the tab into a fixed **2×2 grid** (one root + three `pane split`s).
4. Launches one harness per pane, interactive, task seeded, applying any
   `*_MODEL` override, and renames each pane to its harness.
5. Prints the pane→harness map.

## Notes & guardrails

- **herdr-only.** Requires a running herdr (the script bails if not inside a
  herdr pane). There is no tmux path here — for that, use the orch grid.
- **Shared working tree.** All four panes run in the same `$PWD`. They launch
  with **normal interactive approval prompts** (you approve tool calls), so you
  stay in control; if you let several *write*, their edits share one tree —
  steer them, or point the harnesses at different files.
- **Same task to all four** — the whole point is divergent approaches to the
  identical prompt. There's no sub-task splitting (that's `/orch`).
- Panes persist as shells after a harness exits, so you can rerun or inspect in
  place; close the tab when done.
