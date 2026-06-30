---
description: Write a project-shaped session handoff (.handoffs/HANDOFF.md) so the next session resumes cleanly; auto-drafts, then you tweak.
argument-hint: [optional focus, e.g. "the auth refactor"]
---

Use the **handoff** skill to write a session handoff for the current repo.

Optional focus for this handoff:

$ARGUMENTS

Follow the skill exactly:

- Detect the project profile; gather this session's work + git state + the
  previous handoff's still-open threads.
- Archive any existing `.handoffs/HANDOFF.md`, then write a fresh one (core
  sections + profile sections), keeping the `## ▶ Resume here` heading verbatim.
- Maintain the idempotent `AGENTS.md` pointer block.
- Show the draft for me to tweak, then report the path. **Do not commit** — just
  tell me it is ready to commit.
