---
project: dotfiles
profile: dotfiles
date: 2026-07-22 17:32
branch: main
---

## ▶ Resume here

Nothing is in flight — tree is clean and `main` is pushed (0 ahead). The live
thread is a **watch**: the Core Audio wedge recurred 07-20 and 07-22 and is
still unexplained. If it returns, set `enabled = false` in `[ui.sound]`
(`config/herdr/config.toml`) to actually rule herdr out — see Open questions.

## Goal

Ghostty cursor styling to match the work laptop, plus two problems that
surfaced while working on it: a warm laptop during video playback, and the
recurring system-wide Core Audio wedge.

## Done this session

- **Ghostty cursor shader — the real fix was activation, not tuning.** Vendored
  the work laptop's `cursor_smear.glsl` (hexagonal trail, solid cursor-green
  fill, `DURATION 0.3`, from KroneCorylus/ghostty-shader-playground) into the
  toggle menu. It then sat **commented out for most of the session** while
  `cursor_warp` stayed active, so effort went into making `cursor_warp` imitate
  it — including a move-size-aware duration blend (snappy typing / smooth
  jumps). That was the wrong problem: they are different geometries (hexagon vs
  tapered warp quad). Switching the active line to `cursor_smear.glsl` matched
  the work laptop immediately. `cursor_warp` keeps its duration blend as a menu
  option.
- **Thermal investigation (partial fix).** Watching YouTube in Zen showed
  WindowServer 49% / ghostty 12.5%; video decode itself (VTDecoder,
  hardware-accelerated) was cheap. Cause: `custom-shader-animation = always`
  re-runs the shader every frame forever. Changed to `true`. **Measured result:
  barely any improvement** (47.1% / 12.1%) — in a herdr + agent workspace the
  terminal is never idle, so "on activity" stays busy. Kept anyway (correct, and
  free); the real levers are untried.
- **Core Audio wedge recurred (07-22).** Confirmed with the README runbook:
  `afplay` → `AudioQueueStart failed`, `exit=1`. `sudo killall coreaudiod`
  restarted the daemon cleanly (verified 21s uptime) but did **not** clear it —
  second time in a row that only a reboot worked. Post-reboot `exit=0`.
- **herdr custom sound removed** as a wedge precaution. Deleted
  `config/herdr/sounds/powerup.mp3` and the `sounds/` symlink from
  `bootstrap.sh`. Sound stays **enabled** on herdr's built-in default.
  Verified working: `herdr notification show … --sound done|request` returned
  `shown: true` and both were audible.
- **herdr 0.7.5 config cleanup.** `herdr config check` warned on unknown key
  `theme.custom.background`. That key was never valid — `[theme.custom]` accepts
  only `panel_bg` (which is what takes `"reset"`) and `accent` — so it had been
  a silent no-op. Removed from `config.toml` **and both branches of
  `config/bin/theme`**, which would otherwise rewrite it on the next switch.
  `herdr config check` → `config: ok`.
- **Decided NOT to delete `config/bin/theme`.** It looked unused but is live
  infrastructure: `bootstrap.sh:328` symlinks it, `bootstrap.sh:216-223` seeds
  the `active-theme` pointer + `theme-active.conf` symlink for it, and nvim
  (`config/theme.lua`, `:ThemeReload`, `colorscheme.lua`) reads the pointer it
  writes.
- **4 commits, pushed** (`bfb0678..441a351`).

## Next steps

1. Live with `cursor_smear` for a few days. Tunables at the top of the file
   (`DURATION 0.3`, `saturationBoost 1.8`).
2. Watch for the audio wedge. If it recurs, follow the escalation in Open
   questions — do not just reboot and move on, or we learn nothing.
3. Optional: quantify the thermal levers — measure WindowServer with Ghostty
   fully occluded by a fullscreen video, and with `custom-shader` commented out.
   That tells us whether the shader or the never-idle TUI content dominates.
4. Carried from 07-06, still open: smoke-test the new `<Space>` mappings in
   rmh-wiki's `.obsidian.vimrc` (cross-repo; syncs via Obsidian Sync, not git).
5. Carried from 07-06, still open: exercise `/handoff` from inside aya-town and
   star-rays to validate the `code-app` and `book` profiles.

## Open questions / decisions pending

- **What keeps wedging Core Audio?** Unresolved. The nvim `narrate`/`say`
  triggers were removed in earlier sessions, yet it recurred twice since. herdr
  was the last audio-playing app in this config, but removing its *custom mp3*
  does **not** reduce risk — the built-in default uses the same playback path.
  Escalation ladder: (1) now — sound on, default sound, observe; (2) if it
  recurs — set `[ui.sound] enabled = false` to rule herdr out properly; (3) if
  it recurs even then — herdr is cleared, build a watcher that logs which
  processes hold the Core Audio render callback and what SIGKILL/SIGSTOPs them.
- **Collapse the theme switcher to a single pinned theme?** Offered and not
  taken. Would mean dropping `config/bin/theme` + its bootstrap line, inlining
  ghostty's `theme-active.conf`, hardcoding nvim's colorscheme, and removing
  herdr's managed-block markers. Cost: switching becomes a manual multi-file
  edit. Deferred.
- Carried from 07-06: should handoffs fire automatically at session end via a
  `Stop` hook, rather than only via `/handoff`? Still deferred.

## Landmines / gotchas

- **Ghostty config has no inline comments** — a value runs to end of line, so
  the active `custom-shader` line must be a bare path. A trailing `# …` silently
  disables the shader (it keeps the last line that parsed). Documented in-file.
- **A `custom-shader` change needs a full Ghostty relaunch** — `cmd+shift+,`
  does not reliably reload shaders. Cost this session real debugging time.
- **Check which shader is *active*, not just present.** The whole
  cursor-styling detour came from tuning a shader that wasn't running. When a
  visual doesn't match, verify the active line first.
- **`custom-shader-animation = true` ≠ idle GPU here.** herdr + claude + nvim
  keep the terminal continuously redrawing, so "animate on activity" runs
  almost constantly. Don't expect the power saving the Ghostty docs imply.
- **`sudo killall coreaudiod` is not sufficient** for this wedge — twice now
  only a reboot cleared it. Don't burn time retrying the daemon restart.
- **`config/bin/theme` writes both theme branches.** Any key removed from
  `config/herdr/config.toml`'s managed block must also be removed from *both*
  `case` branches in the script, or the next `theme` switch reinstates it.
- Carried: handoff files go in the **cwd's repo only**; the `## ▶ Resume here`
  heading is a contract for `claude/hooks/handoff-detect.sh` — don't rename.
- Carried: `~/.claude/settings.json` is generated from `claude/settings.json` at
  bootstrap (sed), **not** symlinked — edit the source, never the live file.

## Key files & pointers

- `config/ghostty/config` — shader toggle menu; active line is
  `custom-shader = shaders/cursor_smear.glsl`, plus
  `custom-shader-animation = true`.
- `config/ghostty/shaders/cursor_smear.glsl` — **active**; the work-laptop
  shader, vendored verbatim.
- `config/ghostty/shaders/cursor_warp.glsl` — inactive; holds the move-size-aware
  duration blend (`DURATION_TYPING`, `DURATION_JUMP`, `TYPING_BLEND_MIN/MAX`).
- `config/herdr/config.toml` — `[ui.sound]` (enabled, no custom paths; carries
  the Core Audio caveat) and `[theme.custom]`.
- `config/bin/theme` — the cross-tool switcher; keep in sync with herdr's
  managed block.
- `README.md:328` — the Core Audio "renderer error" runbook (diagnose + fix).
- `.handoffs/archive/2026-07-06-0716.md` — previous handoff.

## Dotfiles-specific

- **Configs changed:** `config/ghostty/config`,
  `config/ghostty/shaders/cursor_smear.glsl` (new),
  `config/ghostty/shaders/cursor_warp.glsl`, `config/herdr/config.toml`,
  `config/bin/theme`, `bootstrap.sh`.
- **Symlink/bootstrap implications:** `bootstrap.sh` no longer links a
  `config/herdr/sounds` dir (deleted along with `powerup.mp3`); the stale
  `~/.config/herdr/sounds` symlink was removed by hand on this machine. Other
  machines clear it on their next bootstrap run. If a custom mp3 is ever added
  back it needs **both** the `sounds/` symlink and a relative
  `ui.sound.*_path`. Everything else reaches `~/.config` via existing symlinks —
  ghostty and herdr changes were live immediately.
- **What to test after `bootstrap.sh`:** `herdr config check` → `config: ok`; no
  dangling `~/.config/herdr/sounds`; Ghostty relaunches with the
  `cursor_smear` trail; `theme toggle` still flips gruvbox ↔ tokyo-night across
  ghostty + herdr + nvim without reintroducing a `background` key.
- **Machine-specific caveats:** herdr is **0.7.5** here (brew) — the
  `theme.custom.background` warning appeared only after that upgrade, so older
  machines may not warn. herdr suppresses notifications for the focused
  workspace (`reason: busy`), so sound can only be tested from a background
  workspace or with herdr unfocused.
