---
name: handoff
description: Write-out session handoff — at the end of a working session, capture where things stand so the next session resumes cleanly. Auto-drafts a project-shaped .handoffs/HANDOFF.md (rolling current + timestamped archive), adapts sections to the project type, and wires discovery via a SessionStart hook (Claude) plus an AGENTS.md pointer (Codex/Pi/OpenCode). Use when ending a session, or when the user says "hand this off", "write a handoff", "save state for next time", or invokes /handoff.
user-invocable: true
---

# handoff — capture session state for the next session

At the end of a working session, write a structured handoff so the next session
picks up cleanly. **Draft automatically** from what you already know, then let
the user tweak. Write files only — **never run git** (no commit, branch, or
push); finish by telling the user the files are ready to commit.

## What you produce

In the current repo — always the repo containing the **current working
directory** (where this session was launched), never another repo, even if the
session's work happened elsewhere. If work touched other repos or vaults,
describe it in the handoff body (Done / Key files & pointers) instead of
writing handoff files there:

- `.handoffs/HANDOFF.md` — the current handoff; the next session reads this first.
- `.handoffs/archive/YYYY-MM-DD-HHMM.md` — the previous HANDOFF.md, archived each run.

Plus an idempotent pointer block in the repo's `AGENTS.md` so non-Claude
harnesses discover the handoff.

## Workflow

1. **Pick the profile.** Match the current repo against the table below (repo
   name first, then content heuristics). Fall back to `generic`.
2. **Gather state** without interrogating the user — ask only if something
   critical is genuinely unknown:
   - what this session did, decided, and tried;
   - for code repos, a git snapshot: `git branch --show-current`,
     `git status --short`, `git log --oneline -5`;
   - the existing `.handoffs/HANDOFF.md` if present — carry forward its
     still-open next-steps and questions (continuity).
3. **Archive.** If `.handoffs/HANDOFF.md` exists, move it to
   `.handoffs/archive/<YYYY-MM-DD-HHMM>.md` (create the dir if needed).
4. **Write** the new `.handoffs/HANDOFF.md` using the structure below.
5. **Maintain the AGENTS.md pointer** (see below).
6. **Show & report.** Show the draft; let the user edit or accept. Report the
   path and that `.handoffs/` is ready to commit. Do not commit.

## Document structure

Always include this core, in this order. Keep the `## ▶ Resume here` heading
verbatim — the SessionStart hook extracts that section.

```markdown
---
project: <repo>
profile: <profile>
date: <YYYY-MM-DD HH:MM>
branch: <branch, for code repos>
---

## ▶ Resume here

<1–3 lines: the first thing to do next.>

## Goal

<what we're working toward — the why.>

## Done this session

<what changed.>

## Next steps

1. <concrete, ordered.>

## Open questions / decisions pending

<unresolved items, or "none".>

## Landmines / gotchas

<dead ends tried, things NOT to do, non-obvious constraints, or "none".>

## Key files & pointers

<where the action is.>
```

Then add the profile-specific sections.

## Profiles

| Repo          | Profile      | Fallback heuristic                                          | Extra sections                                                                                                              |
| ------------- | ------------ | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `aya-town`    | code-app     | `package.json` / `Cargo.toml` / `pyproject.toml` / `go.mod` | repo snapshot; build/test status (green/red); architecture decisions; known bugs; features queued                           |
| `star-rays`   | book         | prose `.md`/`.txt` chapters, no app manifest                | chapter/manuscript status + word counts; continuity & character/plot threads; voice/tone notes; research / fact-check todos |
| `rmh-wiki`    | second-brain | dense interlinked `.md`, `.obsidian/`                       | notes created/edited; links/backlinks added; inbox to process; ongoing threads / MOCs                                       |
| `dotfiles`    | dotfiles     | `bootstrap.sh` + dotfile configs                            | configs changed; symlink/bootstrap implications; what to test after `bootstrap.sh`; machine-specific caveats                |
| *(unmatched)* | generic      | —                                                           | none — core only                                                                                                            |

To support a new project, add a row.

## AGENTS.md pointer

Ensure the repo's `AGENTS.md` contains this managed block. It is idempotent: if
the block is already present, leave it; if `AGENTS.md` exists without it, append
it; if `AGENTS.md` is missing, create it containing only the block.

```markdown
<!-- handoff:begin -->

## Session handoff

If `.handoffs/HANDOFF.md` exists, read it first — it is where the previous
session left off. Recent archives are in `.handoffs/archive/`.

<!-- handoff:end -->
```

Do not edit `CLAUDE.md` — Claude already discovers handoffs via the SessionStart
hook (`~/.claude/hooks/handoff-detect.sh`).

## Guardrails

- Write files only; never run git operations.
- Handoff files go in the current working directory's repo only — cross-repo
  work is *described* in the handoff, never written out to the other repo.
- Draft first, then let the user tweak; ask only when critical info is unknown.
- Keep `## ▶ Resume here` exact so the hook can extract it.
- Stay specific to this session — no boilerplate filler.
