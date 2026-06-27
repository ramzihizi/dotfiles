---
description: Orchestrate a task across heterogeneous CLI agents (conductor + parallel workers + reviewers).
argument-hint: [task to fan out, e.g. "do x, y, and z"]
---

Use the cli-orchestrate skill to run this as the Hermes-style conductor flow:
decompose the task into independent sub-tasks, route each to the best worker
backend (Codex / Pi / agy / Claude), run them in parallel, run
heterogeneous reviewer passes, then gate and present the diffs + verdicts for my
decision.

Use git worktrees only when necessary — i.e. when parallel workers actually write
files that would collide. For read-only / review legs (or a single writer), skip
worktrees and run in place.

**Git is never automatic.** Never run `git merge`, `git branch -D`,
`git worktree remove`, `git commit`, or `git push` without my explicit
go-ahead — always show me the diffs/verdicts and ask first.

**Run it visibly by default:** launch the fan-out through a tmux `grid`
(`scripts/orch-tmux.sh grid <session> <jobs-file>`) so I can watch every agent
live in its own pane — progress and answer — not just a spinner. Prefer
CLI-backed legs (codex/pi/agy/claude) so each one can live in a pane; tell
me the `tmux attach -t <session>` line up front, then poll the out-files and
collect. Only skip the grid if I ask you to.

Treat the arguments below as the task to orchestrate. If it does not split into
2+ independent sub-tasks, say so and just do it directly instead of paying
orchestration overhead.

$ARGUMENTS
