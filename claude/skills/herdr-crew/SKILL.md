---
name: herdr-crew
description: Use when the user wants to spin up the four CLI harnesses (claude, codex, pi, agy) side by side on the SAME task, interactively, in a new tab of the CURRENT herdr workspace — to watch and steer all four live. herdr-only, no judging/worktrees. Triggers - "herdr-crew", "the crew", "all four harnesses on this", "quad harness", "open the crew on X".
---

# herdr-crew — four harnesses, one tab, current workspace

Spin up the four coding **harnesses** — `claude`, `codex`, `pi`, `agy` — each in
its own pane, all in a **new tab of the current herdr workspace**, each launched
**interactively with the same task pre-loaded**, in **auto + read-only mode**:
they run hands-off (no approval prompts) but cannot modify the working tree, so
all four safely share one repo without colliding. You watch all four work side
by side and steer any pane directly. Nothing is captured, scored, or auto-judged
— this is the deliberately-simple, herdr-native cousin of `/bakeoff`.

## Harnesses, not agents

The four panes run the **harness CLIs themselves**, not bare models or
subagents. Each harness drives whatever model it is pointed at; override per
harness before launching. Each launches in **auto + read-only** mode:

| Harness  | Pane         | Read-only + auto launch                                                                                | Model override               |
| -------- | ------------ | ------------------------------------------------------------------------------------------------------ | ---------------------------- |
| `claude` | top-left     | `claude --permission-mode dontAsk --disallowedTools "Edit Write MultiEdit NotebookEdit Bash" "<task>"` | `CLAUDE_MODEL`               |
| `codex`  | top-right    | `codex -s read-only -a never "<task>"`                                                                 | `CODEX_MODEL`                |
| `pi`     | bottom-left  | `pi --tools read,grep,find,ls -a "<task>"`                                                             | `PI_MODEL` (+ `PI_PROVIDER`) |
| `agy`    | bottom-right | `agy -i "<task>"` (see read-only note below)                                                           | `AGY_MODEL`                  |

When the user says "the crew" / "all four harnesses", they mean these four CLIs.

### Read-only enforcement

`claude`, `codex` (read-only sandbox), and `pi` (read-only tool allow-list) are
**hard read-only** — they physically cannot modify the tree and never stop for
approvals. For `claude` this is `dontAsk` mode with the write tools (and `Bash`,
which could write via the shell) denied — **not** plan mode: plan mode gates on
an "exit plan mode to proceed" prompt that reads as "switch to auto" instead of
just returning a result, so it's deliberately avoided. `claude` reviews with
`Read`/`Grep`/`Glob`. `agy` has **no** read-only/plan flag, so it is launched
*without* `--dangerously-skip-permissions`: it can't auto-write, and a write
attempt pauses for you to deny. In addition, the task each harness receives is
prefixed with an explicit **read-only preamble** ("you may read/analyze but must
not create/edit/delete… deliver a report only"), so they frame output as
analysis — this is the primary guard for `agy`.

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
- **Shared working tree — made safe by read-only.** All four panes run in the
  same `$PWD`. Because they're launched **auto + read-only**, sharing one tree is
  safe: claude/codex/pi can't write at all, and agy will pause rather than
  auto-write. That's the whole point — hands-off parallelism without the
  colliding-edits problem. (If you ever want them to actually *implement* and
  compete, that's `/bakeoff`, which gives each its own git worktree.)
- **Same task to all four** — the whole point is divergent approaches to the
  identical prompt. There's no sub-task splitting (that's `/orch`).
- Panes persist as shells after a harness exits, so you can rerun or inspect in
  place; close the tab when done.
