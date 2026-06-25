---
description: Orchestrate a task across heterogeneous CLI agents (conductor + parallel workers + reviewers).
argument-hint: [task to fan out, e.g. "do x, y, and z"]
---

Use the cli-orchestrate skill to run this as the Hermes-style conductor flow:
decompose the task into independent sub-tasks, route each to the best worker
backend (Codex / Pi / OpenCode / Claude), run them in parallel, run
heterogeneous reviewer passes, then gate and merge.

**Run it visibly by default:** launch the fan-out through a tmux `grid`
(`scripts/orch-tmux.sh grid <session> <jobs-file>`) so I can watch every agent
live in its own pane — progress and answer — not just a spinner. Prefer
CLI-backed legs (codex/pi/opencode/claude) so each one can live in a pane; tell
me the `tmux attach -t <session>` line up front, then poll the out-files and
collect. Only skip the grid if I ask you to.

Treat the arguments below as the task to orchestrate. If it does not split into
2+ independent sub-tasks, say so and just do it directly instead of paying
orchestration overhead.

$ARGUMENTS
