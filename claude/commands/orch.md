---
description: Orchestrate a task across heterogeneous CLI agents (conductor + parallel workers + reviewers).
argument-hint: [task to fan out, e.g. "do x, y, and z"]
---

Use the cli-orchestrate skill to run this as the Hermes-style conductor flow:
decompose the task into independent sub-tasks, route each to the best worker
backend (Codex / Pi / OpenCode / Claude subagent), run them in parallel in
isolated git worktrees, run heterogeneous reviewer passes, then gate and merge.

Treat the arguments below as the task to orchestrate. If it does not split into
2+ independent sub-tasks, say so and just do it directly instead of paying
orchestration overhead.

$ARGUMENTS
