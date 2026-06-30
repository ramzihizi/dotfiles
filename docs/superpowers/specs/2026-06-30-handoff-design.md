# Design: `handoff` skill + `/handoff` command

Date: 2026-06-30
Repo: dotfiles
Status: approved (pending spec review)

## Problem

The user runs many Claude sessions per project and hands work from one session
to the next, across several projects with different shapes: **dotfiles**
(configuration), **star-rays** (writing a book), **aya-town** (building an app),
**rmh-wiki** (a second-brain wiki), and more in the future. Today that handoff
is ad hoc. Two gaps:

1. No consistent way to **capture** where a session left off in a form the next
   session can use.
2. Even with a handoff doc, the next session has no reliable way to **discover**
   that it exists — including non-Claude harnesses (Codex, Pi, OpenCode).

## Goal

A `user-invocable` **`handoff`** skill plus a thin **`/handoff`** command that,
at the end of a working session, auto-drafts a structured handoff document whose
*shape* adapts to the project type, and wires up discovery so the next session
(Claude or another harness) picks it up automatically.

Scope is **write-out**: capture state at end of session. Reading back is "read
`HANDOFF.md`", made trivial by the doc's structure. There is no separate
resume/read-in command.

## Decisions (from brainstorming)

- **Direction:** write-out focused.
- **Lifecycle:** rolling current doc + timestamped archive.
- **Location:** in-repo `.handoffs/`, committed to git (syncs across machines;
  archive is durable). The skill never commits — it writes files and reports
  they are ready to commit (per the user's standing "ask before any git
  operation" rule).
- **Profiles:** auto-detected; profile definitions + detection rules live in
  `SKILL.md`. Adding a future project = edit the skill. No per-repo config.
- **Interaction:** auto-draft, then the user tweaks. Ask only when something
  critical is genuinely unknown.
- **Discovery:** both layers — a global `SessionStart` hook for Claude, and a
  local `AGENTS.md` pointer (cross-harness) maintained by the skill.

## Architecture

### Files created / modified (in the dotfiles repo)

| Path                             | Action | Purpose                                                                                                      |
| -------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------ |
| `claude/skills/handoff/SKILL.md` | create | The skill. Auto-symlinks into `~/.claude/skills/` via bootstrap's existing per-skill loop.                   |
| `claude/commands/handoff.md`     | create | Thin command delegating to the skill; optional `$ARGUMENTS` focus hint.                                      |
| `claude/hooks/handoff-detect.sh` | create | `SessionStart` hook that surfaces a waiting handoff. Auto-links via existing `link_dir claude/hooks`.        |
| `claude/settings.json`           | modify | Register the `SessionStart` hook.                                                                            |
| `bootstrap.sh`                   | modify | Add a per-file `claude/commands/*` symlink loop (currently missing — existing commands were linked by hand). |

### Per-project storage layout

```text
<repo>/.handoffs/
  HANDOFF.md                      # current handoff; next session reads this
  archive/
    2026-06-30-1432.md            # previous HANDOFF.md, archived on each run
    2026-06-29-0915.md
```

Archives are kept indefinitely (cheap). `.handoffs/` is committed; not
gitignored.

## Component: the `handoff` skill (`SKILL.md`)

### Frontmatter

```text
name: handoff
description: <triggers — "/handoff", "hand this off", "write a handoff", end-of-session capture>
user-invocable: true
```

### Workflow (`/handoff` run)

1. **Detect profile.** Match the current repo against the profile table (repo
   name first, then content heuristics); fall back to `generic`.
2. **Gather state**, without asking the user unless something critical is
   unknown:
   - This session's work (what was done, decided, attempted).
   - Git snapshot for code repos: branch, `git status` summary, recent commits.
   - The existing `.handoffs/HANDOFF.md`, if present — to carry forward
     unfinished next-steps and still-open questions (continuity).
3. **Archive.** If `.handoffs/HANDOFF.md` exists, move it to
   `.handoffs/archive/YYYY-MM-DD-HHMM.md`. Create `.handoffs/archive/` if
   needed.
4. **Write** the new `.handoffs/HANDOFF.md` (common core + profile sections).
5. **Maintain `AGENTS.md` pointer.** Ensure the repo's `AGENTS.md` contains the
   managed pointer block (idempotent — see below). Create `AGENTS.md` with just
   the block if it does not exist. Do **not** edit `CLAUDE.md` (Claude is
   covered by the hook).
6. **Show & report.** Present the draft for the user to edit or accept. Report
   the written path and that `.handoffs/` is ready to commit. Never commit.

### Handoff document structure

**Common core (every profile), in read-order:**

```markdown
---
project: <repo>
profile: <profile>
date: <YYYY-MM-DD HH:MM>
branch: <git branch, if a code repo>
---

## ▶ Resume here

<1–3 lines: "start by doing X". The single most important thing.>

## Goal

<what we're working toward — the why — so context survives.>

## Done this session

<what changed.>

## Next steps

1. <concrete, ordered.>

## Open questions / decisions pending

<unresolved items.>

## Landmines / gotchas

<dead ends tried, things NOT to do, non-obvious constraints.>

## Key files & pointers

<where the action is.>
```

The `## ▶ Resume here` heading is a fixed marker — the `SessionStart` hook
extracts this section verbatim.

**Profile-specific sections layer on top of the core:**

- **code-app** (aya-town; or repos with `package.json` / `Cargo.toml` /
  `pyproject.toml` / `go.mod`): repo snapshot (branch, uncommitted, last
  commits), build/test status (what's green/red), architecture decisions made,
  known bugs, features queued.
- **book** (star-rays): chapter / manuscript status + word counts, continuity &
  character/plot threads, voice/tone notes, research / fact-check todos.
- **second-brain** (rmh-wiki): notes created/edited, links/backlinks added,
  inbox items to process, ongoing threads / MOCs to revisit.
- **dotfiles** (this repo): configs changed, symlink / bootstrap implications,
  what to test after `bootstrap.sh`, machine-specific caveats.
- **generic** (anything unmatched): common core only — degrades gracefully so a
  brand-new project works day one.

### Profile detection table (lives in `SKILL.md`)

| Repo name     | Profile      | Content fallback heuristic                                          |
| ------------- | ------------ | ------------------------------------------------------------------- |
| `aya-town`    | code-app     | `package.json` / `Cargo.toml` / `pyproject.toml` / `go.mod` present |
| `star-rays`   | book         | many prose `.md`/`.txt` chapters, no app manifest                   |
| `rmh-wiki`    | second-brain | vault-like: dense interlinked `.md`, `.obsidian/`                   |
| `dotfiles`    | dotfiles     | `bootstrap.sh` + dotfile configs present                            |
| *(unmatched)* | generic      | —                                                                   |

Adding a project = add a row.

### `AGENTS.md` managed pointer block

Idempotent, delimited so it can be detected and left alone (or updated) on
repeat runs:

```markdown
<!-- handoff:begin -->

## Session handoff

If `.handoffs/HANDOFF.md` exists, read it first — it is where the previous
session left off. Latest archives are in `.handoffs/archive/`.

<!-- handoff:end -->
```

Rules: if the block exists, leave it; if `AGENTS.md` exists without the block,
append it; if `AGENTS.md` is missing, create it containing only the block.

### Guardrails

- Never run git operations (no commit / branch / push). Write files only.
- Auto-draft then let the user tweak; ask only when critical info is unknown.
- Keep the `## ▶ Resume here` marker exact so the hook can find it.

## Component: the `/handoff` command (`claude/commands/handoff.md`)

Thin delegator mirroring `claude/commands/mini-site.md` and the `legal` pattern.
Frontmatter `description` + `argument-hint`; body says "Use the **handoff**
skill …" and passes `$ARGUMENTS` as an optional focus hint (e.g.
`/handoff focus on the auth refactor`).

## Component: the `SessionStart` hook (`claude/hooks/handoff-detect.sh`)

Purpose: when a new session starts in a repo that has a waiting handoff, inject a
short notice (path + the **▶ Resume here** block) into the session's context.

Behavior:

- Determine the project dir. Hooks run with cwd = project dir, so use `$PWD`
  (optionally refine from the SessionStart stdin JSON `cwd` field if `jq` is
  available; never hard-require `jq`).
- If `$PWD/.handoffs/HANDOFF.md` does not exist, exit 0 silently (the common
  case — must be near-zero cost).
- If it exists, emit a notice containing the file path and the extracted
  `## ▶ Resume here` section (via `awk` from that heading to the next `##`).
- Inject into context via the SessionStart mechanism. **Verify the exact
  contract against current Claude Code hook docs during implementation**
  (plain stdout vs. `hookSpecificOutput.additionalContext` JSON). Prefer the
  documented `additionalContext` form; if JSON escaping needs `jq` and `jq` is
  absent, fall back to plain stdout.

Registration in `claude/settings.json` (the `sed`-templated global settings;
`__HOME__` is substituted at bootstrap):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "__HOME__/.claude/hooks/handoff-detect.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

(Added alongside the existing `PreToolUse` entry, not replacing it.)

## Component: `bootstrap.sh` commands loop

Mirror the existing skills loop so commands link on a fresh machine:

```bash
# Claude commands — link each dotfiles-owned command into ~/.claude/commands.
mkdir -p "$HOME/.claude/commands"
if [[ -d "$DOTFILES_DIR/claude/commands" ]]; then
  for cmd_file in "$DOTFILES_DIR"/claude/commands/*.md; do
    [[ -f "$cmd_file" ]] || continue
    link_file "$cmd_file" "$HOME/.claude/commands/$(basename "$cmd_file")"
  done
fi
```

This also retroactively fixes the existing hand-linked commands.

## Testing / verification

- **Hook, no handoff:** start a session in a repo with no `.handoffs/` → hook
  exits silently, no context injected.
- **Hook, with handoff:** create a `.handoffs/HANDOFF.md` with a
  `## ▶ Resume here` section → the section is surfaced into a new session.
- **Skill, fresh project:** run `/handoff` in a repo with no `.handoffs/` →
  creates `.handoffs/HANDOFF.md` + the `AGENTS.md` block; no archive yet.
- **Skill, repeat:** run again → prior `HANDOFF.md` is archived under
  `.handoffs/archive/`, `AGENTS.md` block unchanged (idempotent).
- **Profiles:** confirm aya-town → code-app, star-rays → book, rmh-wiki →
  second-brain, dotfiles → dotfiles, an unknown repo → generic.
- **bootstrap loop:** dry-run shows `/handoff` (and existing commands) linking.
- **No git side effects:** confirm the skill never stages/commits.

## Out of scope (YAGNI)

- Separate resume/read-in command — read `HANDOFF.md` directly.
- Automatic `Stop`-hook trigger at session end (could add later).
- Auto-commit of `.handoffs/`.
- Per-repo profile override files (table in `SKILL.md` is enough for now).
