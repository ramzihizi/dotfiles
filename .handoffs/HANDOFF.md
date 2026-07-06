---
project: dotfiles
profile: dotfiles
date: 2026-07-06 07:16
branch: main
---

## ▶ Resume here

Commit the two working-tree changes: `claude/skills/handoff/SKILL.md` +
`claude/commands/handoff.md` (handoff now pinned to the cwd's repo). Nothing
else is in flight.

## Goal

Two threads this session: (1) vim-native keybindings in the rmh-wiki Obsidian
vault, and (2) hardening the `handoff` skill after its first cross-repo
dogfood run exposed a placement bug.

## Done this session

- **rmh-wiki vault** (work done there, files live there): extended
  `~/bsdn/rmh-wiki/.obsidian.vimrc` with `unmap <Space>` + a `<Space>t` Tasks
  prefix (`tt` toggle done, `te` create/edit, `to`/`ti`/`tx`/`tc` status
  changes, `tq` query-file defaults) and Neovim-style leaders (`<Space>e`
  sidebar, `<Space><Space>` quick switcher, `<Space>:` command palette).
  Status-command IDs extracted from the Tasks plugin's `main.js`:
  `obsidian-tasks-plugin:set-status-symbol-to-<symbol>` (space → `space`).
  Note: that vimrc is gitignored in rmh-wiki — it syncs via Obsidian Sync,
  nothing to commit there.
- **handoff skill fix**: first `/handoff` run from this repo wrote the
  handoff into rmh-wiki (where the work was) instead of the cwd repo.
  Reverted that (removed rmh-wiki's `.handoffs/` + AGENTS.md block), then
  pinned the skill: handoff files always go in the repo containing the
  session's working directory; cross-repo work is described, not written
  out. Updated both `SKILL.md` (What-you-produce + new guardrail) and the
  `/handoff` command.
- Previous handoff's threads closed: `main` is pushed (0 ahead); the
  `SessionStart` hook is confirmed live (it surfaced the 📋 notice at this
  session's start).

## Next steps

1. Commit `claude/skills/handoff/SKILL.md` + `claude/commands/handoff.md`.
2. Reload Obsidian in rmh-wiki and smoke-test the new `<Space>` mappings
   (especially the four status ones).
3. Still pending from last time: exercise `/handoff` from *within*
   aya-town / star-rays to validate the code-app and book profiles (rmh-wiki's
   second-brain profile got a partial dry run this session).

## Open questions / decisions pending

- Should handoffs ever fire automatically at session end (a `Stop` hook)
  rather than only via `/handoff`? Still deferred.

## Landmines / gotchas

- Handoff placement is now a hard rule: cwd's repo only — even when the
  session's work lives in another repo/vault. Describe cross-repo work in the
  body instead.
- The `## ▶ Resume here` heading is a contract — the hook
  (`claude/hooks/handoff-detect.sh`) extracts it by exact match. Don't rename.
- `~/.claude/settings.json` is generated from `claude/settings.json` at
  bootstrap (sed), NOT symlinked — edit the source, never the live file.
- In Obsidian vimrc land: `nmap` can't call `obcommand` directly (needs an
  `exmap` alias) and mappings must end in `<CR>` since Obsidian 1.7.2.
- rmh-wiki's dirty tree (`2026-W27.md`, the 7/5 journal) predates this
  session — leave it alone.

## Key files & pointers

- `claude/skills/handoff/SKILL.md` — the placement rule + guardrail (edited,
  uncommitted).
- `claude/commands/handoff.md` — same clarification (edited, uncommitted).
- `~/bsdn/rmh-wiki/.obsidian.vimrc` — all new vault mappings (bottom of file).
- `.handoffs/archive/2026-06-30-0951.md` — previous handoff (skill build
  session).

## Dotfiles-specific

- **Configs changed:** `claude/skills/handoff/SKILL.md`,
  `claude/commands/handoff.md` — both reach `~/.claude/` via symlinks, so the
  fix is already live; no regeneration step needed.
- **Symlink/bootstrap implications:** none — no new files, no
  `bootstrap.sh` or `settings.json` changes.
- **What to test after `bootstrap.sh`:** nothing new; unchanged from last
  handoff.
- **Machine-specific caveats:** the rmh-wiki vimrc reaches other machines via
  Obsidian Sync, not this repo — don't expect it in git anywhere.
