---
name: cli-orchestrate
description: Use when the user wants to orchestrate a multi-agent coding flow across heterogeneous CLI backends — Claude Code as conductor dispatching parallel workers (Codex, Pi, OpenCode) with reviewer agents grading their output. The "Hermes" conductor + workers + reviewers pattern. Triggers - "orchestrate", "fan out to codex/pi/opencode", "conductor flow", "run this across the agents", "hermes-style".
---

# cli-orchestrate — heterogeneous agent conductor

Claude Code is the **conductor**. It decomposes a task, routes each sub-task to the
best worker backend, runs them in **parallel in isolated git worktrees**, then runs
**reviewer** passes before merging. This is the local, heterogeneous version of the
Hermes conductor/worker/reviewer flow.

Workers available (see the per-backend skills `codex-cli`, `pi-cli`, `opencode-cli`
for exact flags): **Codex**, **Pi**, **OpenCode**, and **Claude itself** (own subagents).

## When to use

- Task splits into 2+ independent sub-tasks → fan out to parallel workers.
- You want a heterogeneous second opinion (one model writes, a different one reviews).
- You explicitly want the Hermes-style conductor + N workers + M reviewers shape.

For a single small change, just do it directly — don't pay orchestration overhead.

## The dispatch script

`scripts/run-worker.sh <backend> <workdir> <prompt-file> <out-file> [work|review]`

- `backend` ∈ `codex|pi|opencode` · runs headless, captures the worker's final answer to `<out-file>`.
- Model overrides via env: `CODEX_MODEL`, `PI_MODEL`/`PI_PROVIDER`, `OPENCODE_MODEL`/`OPENCODE_AGENT`.
- `WORKER_TIMEOUT` (seconds, default 1200) caps each worker.
- `mode=review` runs read-only (Codex uses `codex exec review`; OpenCode drops `--dangerously-skip-permissions`).

## Routing table — which worker for which sub-task

| Sub-task shape | Route to | Why |
|---|---|---|
| Multi-file design, security-sensitive, ambiguous reasoning | **Claude** (own subagent) | strongest reasoning, keeps conductor context |
| Well-specified single-file implementation, mechanical refactor | **Codex** | fast, cheap, strong sandbox, `-o` clean capture |
| Quick scripted edits, glue, throwaway exploration | **Pi** | minimal, fast spawn, ephemeral `--no-session` |
| Broad multi-file feature with LSP context, alt-provider opinion | **OpenCode** | LSP integration, 75+ providers |
| **Review** of any worker's diff | a **different** backend than wrote it | heterogeneous second opinion catches model-specific blind spots |

Heterogeneous reviewing is the point: never let the same backend write and review the same change.

## Procedure

1. **Decompose.** Break the task into independent sub-tasks. State the split to the user. If sub-tasks share state / must be sequential, say so and run them in order, not parallel.
2. **Isolate.** One git worktree per parallel worker so concurrent edits never collide:
   ```bash
   git worktree add ../wt-<slug> -b orch/<slug>
   ```
   (Skip worktrees for read-only/review tasks.)
3. **Write prompt files.** One self-contained prompt file per sub-task (a worker has none of this conversation's context — include the goal, the files, the acceptance criteria, and "edit files in place").
4. **Fan out.** Launch workers concurrently. Either:
   - shell: run each `run-worker.sh …` in the background (`&`) and `wait`; or
   - launch them as Claude `run_in_background` Bash tasks and collect on completion.
   Cap concurrency at ~4.
5. **Collect.** Read each `<out-file>`. Summarize what each worker did + its worktree/branch.
6. **Review.** For each worker's diff, dispatch a `review` pass to a *different* backend (or use Claude **Agent Teams** — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` — to run parallel security / logic / test-coverage reviewer lenses). Collect verdicts.
7. **Gate + merge.** Only merge worktrees whose review passed. Show the user the diffs and verdicts; merge on approval:
   ```bash
   git merge --no-ff orch/<slug>
   git worktree remove ../wt-<slug>
   ```
   Never auto-merge a failed or unreviewed branch.
8. **Report.** One table: sub-task · backend · worktree · review verdict · merged?

## Visibility — watch it live in a named tmux session

`scripts/orch-tmux.sh` gives the flow a pre-named tmux session so the human can
watch each worker in its own window/pane instead of staring at a spinner.

- **Run mode** — one window per worker, each running the worker live; panes stay open after exit so the result is readable:
  ```bash
  # jobs file: label|backend|workdir|prompt-file|out-file|mode
  cat > /tmp/orch.jobs <<'EOF'
  auth|codex|../wt-auth|/tmp/auth.prompt|/tmp/auth.out|work
  cache|opencode|../wt-cache|/tmp/cache.prompt|/tmp/cache.out|work
  EOF
  scripts/orch-tmux.sh run hermes /tmp/orch.jobs
  # → attach: tmux attach -t hermes   (Ctrl-b d to detach, Ctrl-b w to list windows)
  ```
- **Watch mode** — when the conductor runs workers itself (background Bash) and you only want to tail their outputs in a tiled dashboard:
  ```bash
  scripts/orch-tmux.sh watch hermes /tmp/auth.out /tmp/cache.out
  ```
- Session name is yours to set (`hermes`, `orch`, the task slug). Re-using a live name is refused — `tmux kill-session -t <name>` first.
- When you (Claude) drive this non-interactively, launch with `run`/`watch`, tell the human the `tmux attach -t <name>` command, then poll the out-files for completion. The human watches; you collect and review.

## Worktree-per-worker example

```bash
SK=~/.claude/skills/cli-orchestrate/scripts/run-worker.sh
git worktree add ../wt-auth   -b orch/auth
git worktree add ../wt-cache  -b orch/cache
bash "$SK" codex    ../wt-auth  /tmp/auth.prompt   /tmp/auth.out   work &
bash "$SK" opencode ../wt-cache /tmp/cache.prompt  /tmp/cache.out  work &
wait
# heterogeneous review: pi reviews codex's auth work, codex reviews opencode's cache work
bash "$SK" pi    ../wt-auth  /tmp/auth.review.prompt  /tmp/auth.review.out  review &
bash "$SK" codex ../wt-cache /tmp/cache.review.prompt /tmp/cache.review.out review &
wait
```

## Guardrails

- Workers run with file-write access (`workspace-write` / `--dangerously-skip-permissions`) **inside their worktree** — that's why isolation is mandatory. Run this whole flow inside your trusted environment (the mac-mini, or a sandbox VM).
- Each worker is **context-blind**: the prompt file is its entire world. Under-specified prompts → wasted runs.
- Workers can fail or hang — `WORKER_TIMEOUT` caps them; treat an empty/short `<out-file>` as a failed run, not a silent success.
- Costs are real: parallel heterogeneous workers burn multiple API budgets at once. Scale the worker count to the task.
