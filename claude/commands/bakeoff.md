---
description: Run ONE task across multiple heterogeneous agents in parallel — each attempts the whole task its own way, then judge and keep the best.
argument-hint: [task for every agent to attempt, e.g. "implement X"]
---

Use the cli-orchestrate skill's machinery, but in **best-of-N / bake-off mode** —
the opposite of `/orch`: do **NOT** decompose. Send the *same full task* to
several heterogeneous workers (Codex, Pi, agy, and Claude's own subagent) that
each produce an independent competing solution to the identical problem. Then run
a judge pass that compares them and picks the best one to keep.

**Run it visibly by default:** launch the workers through a tmux `grid`
(`scripts/orch-tmux.sh grid <session> <jobs-file>`) so I can watch every agent
attempt the task live in its own pane — not just a spinner. Tell me the
`tmux attach -t <session>` line up front, then poll the out-files and collect.
Only skip the grid if I ask you to.

Flow:

1. **One prompt, many workers.** Write a single self-contained prompt file (the
   full task + acceptance criteria + "edit files in place"). Every worker gets
   the **same** prompt — no sub-task splitting.
2. **Isolate only if they write in parallel.** When the workers edit files (the
   usual implementation bake-off), give each its own git worktree so the
   competing solutions never collide:
   ```bash
   git worktree add ../bake-<backend> -b bake/<backend>
   ```
   For a read-only / analysis bake-off (each agent only *proposes* an approach,
   writing nothing), skip worktrees and run them in place.
3. **Fan out the identical job** to a *heterogeneous* set — vary the
   backend/model deliberately so you get genuinely different approaches, not N
   copies of one model. Writer legs are codex/pi/agy (each lives in a pane —
   note agy's run-worker keyword is still `opencode`); for a Claude *writer* leg
   use the in-process Agent tool (it won't be a pane — say so). Cap ~4 workers.
4. **Judge.** Collect every worker's diff and run a judge pass — a backend that
   did **not** write (the review-only `claude` leg, or Claude reviewer lenses) —
   that reads all N solutions side by side and ranks them on correctness,
   simplicity, and fit, naming a winner with reasons. Flag any good ideas from
   the runners-up worth grafting onto the winner.
5. **Pick — then stop and discuss.** Show me the ranked results, the diffs, and
   the judge's recommendation, and **wait**. Do NOT merge, cherry-pick, delete
   branches, or remove worktrees on your own. I decide what happens to the winner
   — merge it, graft the best pieces from the others, keep a branch, or throw it
   all away. Leave every `bake/<backend>` worktree and branch in place until I
   say so.
6. **Report.** One table: backend · model · worktree · judge rank · notes ·
   recommendation. Then we discuss the outcome — the next step is mine to call.

**Git is never automatic here.** Never run `git merge`, `git branch -D`,
`git worktree remove`, `git commit`, or `git push` without my explicit
go-ahead — always show me the diffs/verdicts and ask first.

The whole point is *diversity of approach* — vary the models so the attempts
genuinely diverge, then let the best one win. If the task is trivial or has one
obvious implementation, say so and just do it directly instead of paying for N
parallel attempts.

$ARGUMENTS
