---
name: codex-cli
description: Use when delegating a coding sub-task to OpenAI's Codex CLI as a headless worker, or getting a Codex second-opinion code review. Claude shells out to `codex exec`, reads the result back, and decides next steps. Triggers - "hand this to codex", "have codex implement/review", "codex worker", or as a worker leg of cli-orchestrate.
---

# codex-cli — Codex as a headless worker

`codex` (v0.142+) is installed. Run it non-interactively with `codex exec`; Claude
stays the conductor and reads Codex's final message back.

## Implementation run

```bash
codex exec \
  -C <workdir> \                 # working root (a git worktree for parallel safety)
  -s workspace-write \           # sandbox: read-only | workspace-write | danger-full-access
  --skip-git-repo-check \        # allow running where needed
  -o <out-file> \                # writes ONLY the agent's final message here (clean capture)
  "<self-contained task prompt>"
```

- Read `<out-file>` for the distilled result; stdout carries the full transcript.
- Add `--json` for JSONL events if you need to parse tool calls / progress.
- `-m <model>` overrides the model. `--add-dir <dir>` grants extra writable roots.
- Resume a session: `codex exec resume --last "<follow-up>"`.
- Prompt can come from stdin instead of an arg: `codex exec -o out.txt - < prompt.txt`.

## Review run (read-only second opinion)

```bash
codex exec review --skip-git-repo-check "<what to review and against what>"
```
Run inside the target worktree (`cd` first). Good as the heterogeneous reviewer for
work another backend (Pi/OpenCode/Claude) wrote — Codex won't review its own diff.

## Notes

- Sandbox is Apple Seatbelt; `workspace-write` lets it edit files but network is restricted by default — fine for most coding, but a task needing network may need config.
- Prompt is the worker's entire context. Include goal, target files, acceptance criteria, and "edit files in place."
- Treat an empty `<out-file>` or non-zero exit as a failed run.
- The `cli-orchestrate` skill's `run-worker.sh codex …` wraps all of this (timeout, capture, review mode).
