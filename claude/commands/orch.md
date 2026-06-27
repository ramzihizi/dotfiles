---
description: Orchestrate a task across heterogeneous CLI agents (conductor + parallel workers + reviewers).
argument-hint: [task to fan out, e.g. "do x, y, and z"]
---

Use the cli-orchestrate skill to run this as the Hermes-style conductor flow:
decompose the task into independent sub-tasks, route each to the best worker
**harness** (the CLIs `codex` / `pi` / `agy` / `claude` — each drives its own
model via `*_MODEL` env; you fan out and review the harnesses, not bare agents),
run them in parallel, run heterogeneous reviewer passes, then gate and present
the diffs + verdicts for my decision.

Use git worktrees only when necessary — i.e. when parallel workers actually write
files that would collide. For read-only / review legs (or a single writer), skip
worktrees and run in place.

**Git is never automatic.** Never run `git merge`, `git branch -D`,
`git worktree remove`, `git commit`, or `git push` without my explicit
go-ahead — always show me the diffs/verdicts and ask first.

**Run it visibly by default:** launch the fan-out through a `grid`
(`scripts/orch-mux.sh grid <session> <jobs-file>`) so I can watch every agent
live in its own pane — progress and answer — not just a spinner. `orch-mux.sh`
runs the grid under **tmux or herdr, chosen at prompt time**: it auto-detects my
current multiplexer (`$TMUX` → tmux, `$HERDR_ENV` → herdr), but honor it if I
say "use tmux" / "use herdr" (force with a leading `tmux`/`herdr` token or
`ORCH_MUX=`). Prefer CLI-backed legs (codex/pi/agy/claude) so each one can live
in a pane; tell me the attach/focus line the script prints up front (tmux:
`tmux attach -t <session>`; herdr: `herdr workspace focus <id>`), then poll the
out-files and collect. Only skip the grid if I ask you to.

Treat the arguments below as the task to orchestrate. If it does not split into
2+ independent sub-tasks, say so and just do it directly instead of paying
orchestration overhead.

$ARGUMENTS
