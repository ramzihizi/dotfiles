---
name: pi-cli
description: Use when delegating a coding sub-task to the Pi agent CLI (pi.dev) as a headless worker. Pi is minimal and fast to spawn — good for quick scripted edits, glue, and throwaway exploration. Claude shells out to `pi -p`, reads stdout back. Triggers - "hand this to pi", "have pi do X", "pi worker", or as a worker leg of cli-orchestrate.
---

# pi-cli — Pi as a headless worker

`pi` (v0.79+) is installed. Minimal terminal coding harness; deliberately has **no
sub-agents** — you orchestrate Pi *instances*. That makes it a clean, cheap worker.

## Headless run

Pi has **no `--cd` flag** — it runs in the current directory, so `cd` into the
worktree first:

```bash
( cd <workdir> && pi -p --no-session -a "<self-contained task prompt>" )   # stdout = result
```

- `-p` / `--print` — non-interactive: process the prompt and exit.
- `--no-session` — ephemeral, don't persist a session file (right for disposable workers).
- `-a` / `--approve` — trust project-local files (AGENTS.md/CLAUDE.md/extensions) for this run.
- `--mode json` — structured output instead of plain text, if you need to parse it.
- `--model <pattern>` / `--provider <name>` — override (defaults to its configured provider).
- `--continue` / `--session <id>` — resume a prior session.
- `-t <tools>` / `-xt <tools>` — allowlist / denylist tools (e.g. `-t read,bash,edit,write`).

## Notes

- Capture is just stdout — redirect it: `… > out.txt`.
- Pi loads `AGENTS.md`/`CLAUDE.md` by default (disable with `-nc`); with `-a` it trusts them without prompting.
- Best routed the quick/mechanical/throwaway sub-tasks; for heavy multi-file reasoning prefer Claude or OpenCode.
- As a heterogeneous **reviewer**: `( cd <worktree> && pi -p --no-session -a "Review the staged diff for bugs/security; do not edit." )`.
- The `cli-orchestrate` skill's `run-worker.sh pi …` wraps this (timeout, capture, model env).
