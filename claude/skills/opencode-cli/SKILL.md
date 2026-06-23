---
name: opencode-cli
description: Use when delegating a coding sub-task to the OpenCode agent CLI as a headless worker. OpenCode has LSP integration and 75+ providers — good for broad multi-file features and alternate-provider second opinions. Claude shells out to `opencode run`, reads output back. Triggers - "hand this to opencode", "have opencode do X", "opencode worker", or as a worker leg of cli-orchestrate.
---

# opencode-cli — OpenCode as a headless worker

`opencode` (v1.17+) is installed. Terminal agent with LSP integration and many
providers. Run headless with `opencode run`.

## Headless run

```bash
opencode run \
  --dir <workdir> \                  # working directory (a git worktree for parallel safety)
  --dangerously-skip-permissions \   # auto-approve non-denied permissions (needed for unattended edits)
  --model <provider/model> \         # optional; e.g. anthropic/claude-..., openai/...
  --agent <name> \                   # optional named agent profile
  "<self-contained task prompt>"
```

- `--format json` — raw JSON event stream instead of formatted output, if you need to parse.
- `--variant high|max|minimal` — provider-specific reasoning effort.
- `-c` / `--session <id>` — continue / resume; `--fork` forks before continuing.
- Manage profiles with `opencode agent`; list models with `opencode models`.

## Notes

- Capture is stdout — redirect it: `… > out.txt`.
- `--dir` means you do **not** need to `cd` (unlike Pi).
- Drop `--dangerously-skip-permissions` for a **review** pass so it stays read-only:
  `opencode run --dir <worktree> --format default "Review this diff for bugs/security; do not edit."`
- Its 75+ providers make it the natural pick when you want a review or implementation from a *different* model family than wrote the code.
- The `cli-orchestrate` skill's `run-worker.sh opencode …` wraps this (timeout, capture, model/agent env, auto review mode).
