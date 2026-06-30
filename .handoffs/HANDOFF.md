---
project: dotfiles
profile: dotfiles
date: 2026-06-30 09:51
branch: main
---

## ▶ Resume here

The `handoff` skill + `/handoff` command are built, merged to `main`, and live.
Nothing is in flight. If you continue, the obvious next step is to **push `main`
to origin** (it's ahead by 7) — or exercise `/handoff` in a real project
(aya-town, star-rays, rmh-wiki) to validate the non-dotfiles profiles.

## Goal

Give the user a repeatable way to hand work from one session to the next across
many projects: a project-shaped handoff doc the next session reads, plus
automatic discovery so it actually gets read.

## Done this session

- Designed + built the `handoff` feature end-to-end (spec → plan → implement →
  merge). 7 commits, fast-forwarded onto `main`.
- New artifacts: `claude/skills/handoff/SKILL.md`, `claude/commands/handoff.md`,
  `claude/hooks/handoff-detect.sh`, a `SessionStart` entry in
  `claude/settings.json`, and a commands symlink loop in `bootstrap.sh`.
- Spec + plan in `docs/superpowers/specs/` and `docs/superpowers/plans/`.
- Dogfooded: this file is the first real `/handoff` output.

## Next steps

1. Push `main` to origin (7 commits ahead) — user said to push after this.
2. Live smoke test on a **fresh** session: confirm the `SessionStart` hook
   surfaces the "📋 handoff waiting" notice with the Resume-here lines.
3. Try `/handoff` in aya-town / star-rays / rmh-wiki to shake out the
   code-app / book / second-brain profiles against real repos.

## Open questions / decisions pending

- Should handoffs ever fire automatically at session end (a `Stop` hook),
  rather than only on demand via `/handoff`? Deferred as out-of-scope for now.

## Landmines / gotchas

- The `## ▶ Resume here` heading is a contract: the hook
  (`claude/hooks/handoff-detect.sh`) extracts that section by exact match.
  Don't rename it.
- `~/.claude/settings.json` is **generated** from `claude/settings.json` via
  `sed s/__HOME__/.../` at bootstrap — it is NOT symlinked. Editing the live
  file directly will be overwritten on next bootstrap; edit the source.
- The dprint PostToolUse format hook normalizes markdown across the repo on
  write — expect incidental reformat diffs in unrelated `.md` files (this
  session picked up a blank-line fix in `README.md`; left uncommitted/flagged).
- The skill never runs git by design; committing/pushing is always the user's
  explicit call.

## Key files & pointers

- Skill: `claude/skills/handoff/SKILL.md` (profile table lives here — add a row
  to support a new project).
- Hook: `claude/hooks/handoff-detect.sh` (whole `claude/hooks/` dir is
  symlinked, so new hooks go live immediately).
- Command: `claude/commands/handoff.md`.
- Spec/plan: `docs/superpowers/specs/2026-06-30-handoff-design.md`,
  `docs/superpowers/plans/2026-06-30-handoff.md`.

## Dotfiles-specific

- **Configs changed:** `claude/settings.json` (added `SessionStart` hook);
  `bootstrap.sh` (added a per-file `claude/commands/*` symlink loop that also
  retroactively fixes the previously hand-linked commands).
- **Symlink/bootstrap implications:** on a fresh machine, `bootstrap.sh` now
  links commands automatically; skills + hooks already linked via existing
  loops. Verify with a dry run after pulling.
- **What to test after `bootstrap.sh`:** `~/.claude/commands/handoff.md` and
  `~/.claude/skills/handoff/SKILL.md` resolve; `~/.claude/settings.json` has the
  `SessionStart` entry pointing at a real hook path.
- **Machine-specific caveats:** the hook prefers the SessionStart payload's
  `cwd` only when `jq` is present, else falls back to `$PWD` — no hard `jq`
  dependency.
