---
name: cli-orchestrate
description: Use when the user wants to orchestrate a multi-agent coding flow across heterogeneous CLI backends — Claude Code as conductor dispatching parallel workers (Codex, Pi, agy) with reviewer agents grading their output. The "Hermes" conductor + workers + reviewers pattern. Triggers - "orchestrate", "fan out to codex/pi/agy", "conductor flow", "run this across the agents", "hermes-style".
---

# cli-orchestrate — heterogeneous agent conductor

Claude Code is the **conductor**. It decomposes a task, routes each sub-task to the
best worker backend, runs them in **parallel in isolated git worktrees**, then runs
**reviewer** passes before merging. This is the local, heterogeneous version of the
Hermes conductor/worker/reviewer flow.

Workers are the **CLI harnesses** themselves — `codex`, `pi`, `agy`, `claude` —
not bare models. Each harness drives whatever model/agent it's pointed at (set
per leg via `CODEX_MODEL`/`PI_MODEL`/`AGY_MODEL`/`CLAUDE_MODEL`); the harness is
the unit you fan out and review. Available (see the per-backend skills
`codex-cli`, `pi-cli` for exact flags): **Codex**, **Pi**, **agy** (the new agent
harness — replaced OpenCode), and **Claude itself** (`claude -p`, plus the
conductor's own in-process subagents for file-writing legs).

## When to use

- Task splits into 2+ independent sub-tasks → fan out to parallel workers.
- You want a heterogeneous second opinion (one model writes, a different one reviews).
- You explicitly want the Hermes-style conductor + N workers + M reviewers shape.

For a single small change, just do it directly — don't pay orchestration overhead.

## The dispatch script

`scripts/run-worker.sh <backend> <workdir> <prompt-file> <out-file> [work|review]`

- `backend` ∈ `codex|pi|agy|claude` · runs headless, captures the worker's final answer to `<out-file>`.
- Model overrides via env: `CODEX_MODEL`, `PI_MODEL`/`PI_PROVIDER`, `AGY_MODEL`, `CLAUDE_MODEL`.
- `WORKER_TIMEOUT` (seconds, default 1200) caps each worker.
- `mode=review` runs read-only (Codex uses `codex exec review`; agy drops `--dangerously-skip-permissions`).
- The **`claude` backend is review-only** (`claude -p`, no file-writing flag) — use it as a *visible-pane* Claude critic/reviewer leg. For a file-*writing* Claude leg, use the conductor's own Agent tool (in-process, not a pane) or route the write to codex/pi/agy.

## Routing table — which worker for which sub-task

| Sub-task shape                                                 | Route to                              | Why                                                             |
| -------------------------------------------------------------- | ------------------------------------- | --------------------------------------------------------------- |
| Multi-file design, security-sensitive, ambiguous reasoning     | **Claude** (own subagent)             | strongest reasoning, keeps conductor context                    |
| Well-specified single-file implementation, mechanical refactor | **Codex**                             | fast, cheap, strong sandbox, `-o` clean capture                 |
| Quick scripted edits, glue, throwaway exploration              | **Pi**                                | minimal, fast spawn, ephemeral `--no-session`                   |
| Broad multi-file feature, alt-harness second opinion           | **agy**                               | Claude-Code-style agent harness (replaced OpenCode)             |
| **Review** of any worker's diff                                | a **different** backend than wrote it | heterogeneous second opinion catches model-specific blind spots |

Heterogeneous reviewing is the point: never let the same backend write and review the same change.

## Procedure

> **Visibility is the default.** Unless the user says otherwise, run the fan-out through a **`grid`** (see below) so the human sees every agent live in its own pane — progress *and* answer — instead of a spinner. The grid runs under **either tmux or herdr**, picked at prompt time via `orch-mux.sh` (auto-detected from the current environment; override by saying "use tmux"/"use herdr"). Prefer CLI-backed legs (`codex`/`pi`/`agy`/`claude` — the worker *harnesses*) over the in-process Agent tool when running a grid, because only CLI workers can live in a pane. Launch the grid, tell the user the attach/focus line it prints, then poll the out-files to collect.

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

## Visibility — watch it live in a named session (default for `/orch`)

`scripts/orch-mux.sh` gives the flow a pre-named, visible session so the human
can watch each agent live instead of staring at a spinner. It is a thin front
door over two interchangeable backends — **tmux** (`orch-tmux.sh`, a tmux
session) and **herdr** (`orch-herdr.sh`, a herdr workspace) — that share the
exact same `grid|run|watch <session> <args>` interface and jobs-file format.
**Default to `grid`.**

**Which multiplexer (decide at prompt time).** `orch-mux.sh` auto-detects from
the conductor's environment — `$TMUX` set → tmux; `$HERDR_ENV`/`$HERDR_PANE_ID`
set (or a reachable herdr server) → herdr. The user can override per run by
saying "use tmux" / "use herdr"; force it with a leading token
(`orch-mux.sh herdr grid …`) or `ORCH_MUX=tmux`. Everything below is identical
on both — only the attach gesture differs (tmux: `tmux attach -t <s>`; herdr:
`herdr workspace focus <id>` or the `prefix+w` picker), and `orch-mux.sh` prints
the right one.

- **Grid mode (the default)** — every worker live in its own tiled **pane**, side by side; each pane streams that worker's progress, then prints its final answer, then stays open:
  ```bash
  # jobs file: label|backend|workdir|prompt-file|out-file|mode
  cat > /tmp/orch.jobs <<'EOF'
  critique-codex|codex|.|/tmp/crit.prompt|/tmp/codex.out|review
  critique-pi|pi|.|/tmp/crit.prompt|/tmp/pi.out|review
  critique-claude|claude|.|/tmp/crit.prompt|/tmp/claude.out|review
  EOF
  scripts/orch-mux.sh grid orch /tmp/orch.jobs       # auto-detect tmux vs herdr
  # tmux  → attach: tmux attach -t orch   (Ctrl-b z zoom · Ctrl-b o cycle · Ctrl-b d detach)
  # herdr → focus:  herdr workspace focus <id>   (prefix+| / prefix+- split · prefix+w picker)
  ```
- **Run mode** — one **window** (tmux) / **tab** (herdr) per worker. Use when output is long and panes would be too cramped to read:
  ```bash
  scripts/orch-mux.sh run orch /tmp/orch.jobs
  ```
- **Watch mode** — when the conductor runs workers itself (background Bash) and you only want to tail their out-files in a tiled dashboard:
  ```bash
  scripts/orch-mux.sh watch orch /tmp/codex.out /tmp/pi.out /tmp/claude.out
  ```
- Session name is yours to set (`orch`, `hermes`, the task slug). Re-using a live name is refused — `tmux kill-session -t <name>` (tmux) or `herdr workspace close <id>` (herdr) first.
- **How you (Claude) drive it:** write the prompt + jobs file, launch `grid` via `orch-mux.sh`, tell the human the attach/focus line it printed up front, then poll the out-files for completion and collect. The human watches the panes; you read the out-files and judge. To put a Claude leg in a pane, use the `claude` backend (review-only); reserve the in-process Agent tool for a leg that must *write* files or hold this conversation's context (it won't appear as a pane — say so).

## Worktree-per-worker example

```bash
SK=~/.claude/skills/cli-orchestrate/scripts/run-worker.sh
git worktree add ../wt-auth   -b orch/auth
git worktree add ../wt-cache  -b orch/cache
bash "$SK" codex    ../wt-auth  /tmp/auth.prompt   /tmp/auth.out   work &
bash "$SK" agy      ../wt-cache /tmp/cache.prompt  /tmp/cache.out  work &
wait
# heterogeneous review: pi reviews codex's auth work, codex reviews agy's cache work
bash "$SK" pi    ../wt-auth  /tmp/auth.review.prompt  /tmp/auth.review.out  review &
bash "$SK" codex ../wt-cache /tmp/cache.review.prompt /tmp/cache.review.out review &
wait
```

## Guardrails

- Workers run with file-write access (`workspace-write` / `--dangerously-skip-permissions`) **inside their worktree** — that's why isolation is mandatory. Run this whole flow inside your trusted environment (the mac-mini, or a sandbox VM).
- Each worker is **context-blind**: the prompt file is its entire world. Under-specified prompts → wasted runs.
- Workers can fail or hang — `WORKER_TIMEOUT` caps them; treat an empty/short `<out-file>` as a failed run, not a silent success.
- Costs are real: parallel heterogeneous workers burn multiple API budgets at once. Scale the worker count to the task.
