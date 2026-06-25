# Kokoro-in-Neovim narration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `<leader>dR` Neovim hotkey that reads the visual selection aloud with a natural Kokoro voice, reusing Murmur's bundled mlx-audio runtime, alongside the existing `/usr/bin/say` keymap.

**Architecture:** A standalone `narrate` shell script reads text on stdin and synthesizes speech by invoking Murmur's bundled `mlx-audio` venv (Kokoro model) with `HF_HOME` pointed at Murmur's HuggingFace cache, writing a temp WAV and playing it with `afplay`. Neovim pipes the visual selection to `narrate` via `jobstart`. No new runtime or model is installed — both are borrowed from Murmur.

**Tech Stack:** Bash, `afplay`, Murmur's `mlx-audio 0.4.1` venv (Python 3.11, Kokoro `prince-canuma/Kokoro-82M`), Neovim Lua.

## Global Constraints

- Markdown is auto-formatted by dprint on Write/Edit; fenced code blocks need a language; no bare URLs; space after heading hashes (see `CLAUDE.md`).
- Murmur bridge dir (verbatim): `~/Library/Application Support/Murmur/MLXAudioBridge/com.murmur.app`.
- Venv python: `<bridge>/venv/bin/python`; HF cache: `<bridge>/huggingface`.
- Kokoro model repo: `prince-canuma/Kokoro-82M`. Default voice: `af_heart` (override via `NARRATE_VOICE`).
- mlx-audio CLI: `python -m mlx_audio.tts.generate` with `--model --voice --text --output_path --file_prefix --audio_format wav --join_audio`. Output file is `<output_path>/<file_prefix>.wav`.
- Keep `<leader>dr` (`say`) unchanged. New key is `<leader>dR`. `<leader>ds` stops both engines.
- Existing nvim helpers to follow: `visual_selection()`, `speak(text)`, `stop_speech()`, `speech_job` in `config/nvim/lua/config/keymaps.lua`.

---

## File Structure

- Create: `config/bin/narrate` — stdin → Kokoro speech → afplay. Single responsibility.
- Modify: `bootstrap.sh` — symlink `narrate` into `~/.local/bin`.
- Modify: `config/nvim/lua/config/keymaps.lua` — add `narrate()` helper, `<leader>dR` map, extend `stop_speech()`.
- Modify: `docs/nvim-cheatsheet.md` — document the two-layer read-aloud setup.

---

### Task 1: `narrate` script + bootstrap symlink

**Files:**

- Create: `config/bin/narrate`
- Modify: `bootstrap.sh` (Symlink Configurations section, near the other `link_file` calls)

**Interfaces:**

- Consumes: nothing (entry point).
- Produces: an executable `narrate` on `PATH` that reads text on stdin and plays it. Neovim (Task 2) invokes it at `~/.local/bin/narrate`.

- [ ] **Step 1: Write the script**

Create `config/bin/narrate`:

```bash
#!/usr/bin/env bash
# narrate — read stdin text aloud with a Kokoro voice, reusing Murmur's
# bundled mlx-audio runtime. Mirrors /usr/bin/say's stdin interface:
#   echo "hello there" | narrate
# Config: NARRATE_VOICE (default af_heart).
set -euo pipefail

BRIDGE="$HOME/Library/Application Support/Murmur/MLXAudioBridge/com.murmur.app"
PYTHON="$BRIDGE/venv/bin/python"
MODEL="prince-canuma/Kokoro-82M"
VOICE="${NARRATE_VOICE:-af_heart}"

if [[ ! -x "$PYTHON" ]]; then
  echo "narrate: Murmur runtime not found at:" >&2
  echo "  $PYTHON" >&2
  echo "narrate: open Murmur once (or reinstall) to provision its mlx-audio venv." >&2
  exit 1
fi

text="$(cat)"
if [[ -z "${text//[[:space:]]/}" ]]; then
  echo "narrate: no input text" >&2
  exit 1
fi

workdir="$(mktemp -d "${TMPDIR:-/tmp}/narrate.XXXXXX")"
trap 'rm -rf "$workdir"' EXIT INT TERM

export HF_HOME="$BRIDGE/huggingface"

"$PYTHON" -m mlx_audio.tts.generate \
  --model "$MODEL" \
  --voice "$VOICE" \
  --text "$text" \
  --output_path "$workdir" \
  --file_prefix narrate \
  --audio_format wav \
  --join_audio >/dev/null 2>&1

wav="$workdir/narrate.wav"
if [[ ! -f "$wav" ]]; then
  # Fall back to any wav the generator produced (segment naming varies).
  wav="$(/bin/ls "$workdir"/*.wav 2>/dev/null | head -n1 || true)"
fi
if [[ -z "${wav:-}" || ! -f "$wav" ]]; then
  echo "narrate: synthesis produced no audio" >&2
  exit 1
fi

afplay "$wav"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x config/bin/narrate && ls -l config/bin/narrate`
Expected: mode shows `-rwxr-xr-x` (executable bits set).

- [ ] **Step 3: Verify empty-input handling (no model load)**

Run: `printf '' | ./config/bin/narrate; echo "exit=$?"`
Expected: prints `narrate: no input text` to stderr and `exit=1`.

- [ ] **Step 4: Verify missing-runtime handling**

Run: `BRIDGE_OVERRIDE=1 HOME=/nonexistent ./config/bin/narrate <<<"hi"; echo "exit=$?"`
Expected: prints the "Murmur runtime not found" message and `exit=1`.
(The script derives `BRIDGE` from `$HOME`; pointing `HOME` at a nonexistent dir makes the venv path missing without touching the real install.)

- [ ] **Step 5: Verify real synthesis end-to-end**

Run: `echo "Testing one two three." | ./config/bin/narrate; echo "exit=$?"`
Expected: audible Kokoro speech; `exit=0`. First run also downloads `prince-canuma/Kokoro-82M` (~160 MB) into Murmur's shared cache — allow extra time. Re-running is faster.

- [ ] **Step 6: Verify temp cleanup**

Run: `ls -d "${TMPDIR:-/tmp}"/narrate.* 2>/dev/null; echo "leftovers above (should be none)"`
Expected: no `narrate.*` temp dirs remain after Step 5 completed.

- [ ] **Step 7: Add the bootstrap symlink**

In `bootstrap.sh`, find the "Symlink Configurations" section (after `mkdir -p "$HOME/.config"`). Add, near the other `link_file` calls:

```bash
# narrate (Kokoro read-aloud CLI; reuses Murmur's bundled mlx-audio runtime)
mkdir -p "$HOME/.local/bin"
link_file "$DOTFILES_DIR/config/bin/narrate" "$HOME/.local/bin/narrate"
```

- [ ] **Step 8: Apply the symlink and verify it resolves on PATH**

Run: `mkdir -p "$HOME/.local/bin" && ln -sf "$PWD/config/bin/narrate" "$HOME/.local/bin/narrate" && command -v narrate`
Expected: prints `/Users/rmh/.local/bin/narrate`.

- [ ] **Step 9: Verify via PATH**

Run: `echo "Hooked up." | narrate; echo "exit=$?"`
Expected: audible speech; `exit=0`.

- [ ] **Step 10: Commit**

```bash
git add config/bin/narrate bootstrap.sh
git commit -m "Add narrate CLI reusing Murmur's mlx-audio for Kokoro read-aloud"
```

---

### Task 2: Neovim `<leader>dR` keymap

**Files:**

- Modify: `config/nvim/lua/config/keymaps.lua`

**Interfaces:**

- Consumes: `~/.local/bin/narrate` (Task 1); existing `visual_selection()`, `stop_speech()`, `speak()`.
- Produces: `<leader>dR` (visual) reads selection via Kokoro; `<leader>ds` stops both `say` and `narrate`.

- [ ] **Step 1: Add a job handle and the `narrate` helper**

After the existing `speak(text)` function (ends around line 65, before the keymaps), add:

```lua
local narrate_job

local function narrate(text)
  text = vim.trim(text or "")
  if text == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  stop_speech()

  local bin = vim.fn.expand("~/.local/bin/narrate")
  if vim.fn.executable(bin) == 0 then
    vim.notify("narrate not found at " .. bin, vim.log.levels.ERROR)
    return
  end

  narrate_job = vim.fn.jobstart({ bin }, {
    on_exit = function()
      narrate_job = nil
    end,
  })

  if narrate_job <= 0 then
    narrate_job = nil
    vim.notify("Could not start narrate", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(narrate_job, text)
  vim.fn.chanclose(narrate_job, "stdin")
end
```

- [ ] **Step 2: Extend `stop_speech()` to cover narrate + afplay**

In the existing `stop_speech()` function (lines ~34-41), replace its body so it stops both engines:

```lua
local function stop_speech()
  if speech_job then
    vim.fn.jobstop(speech_job)
    speech_job = nil
  end

  if narrate_job then
    vim.fn.jobstop(narrate_job)
    narrate_job = nil
  end

  vim.fn.system({ "/usr/bin/pkill", "-x", "say" })
  vim.fn.system({ "/usr/bin/pkill", "-x", "afplay" })
end
```

Note: `stop_speech` is referenced by both `speak` and `narrate`, and `narrate` references `narrate_job`. Declare `local narrate_job` (Step 1) and `local speech_job` (already at line 32) above `stop_speech`. If ordering causes a "narrate_job not defined" issue, move the `local narrate_job` declaration up next to `local speech_job`.

- [ ] **Step 3: Add the `<leader>dR` mapping**

Next to the existing `<leader>dr` visual mapping (around line 75), add:

```lua
vim.keymap.set("x", "<leader>dR", function()
  narrate(visual_selection())
end, { desc = "Read Selection (Kokoro)" })
```

- [ ] **Step 4: Reload and check for Lua errors**

Run: `nvim --headless "+luafile config/nvim/lua/config/keymaps.lua" +qa 2>&1; echo "exit=$?"`
Expected: no error output; `exit=0`. (If it reports requiring a running config context, instead open nvim normally and run `:messages` — expected: no errors.)

- [ ] **Step 5: Manual verification in Neovim**

Open a file in nvim, select a sentence in visual mode, press `<leader>dR`.
Expected: audible Kokoro narration. Press `<leader>ds` mid-playback → audio stops. Confirm `<leader>dr` still uses `say`, and `<leader>ds` also stops `say`.

- [ ] **Step 6: Commit**

```bash
git add config/nvim/lua/config/keymaps.lua
git commit -m "Add <leader>dR Neovim keymap for Kokoro read-aloud"
```

---

### Task 3: Document the read-aloud setup

**Files:**

- Modify: `docs/nvim-cheatsheet.md`

**Interfaces:**

- Consumes: nothing.
- Produces: user-facing docs for the two-layer setup.

- [ ] **Step 1: Add a read-aloud section**

Append to `docs/nvim-cheatsheet.md` (adjust heading level to match the file's existing sections):

```markdown
## Read aloud (text-to-speech)

Two engines, both driven from visual mode:

- `<leader>dr` — read selection with macOS `say` (instant, robotic).
- `<leader>dR` — read selection with a natural Kokoro voice via the `narrate`
  CLI.
- `<leader>ds` — stop either engine.

`narrate` reuses the [Murmur](https://www.murmurtts.com/) app's bundled
`mlx-audio` runtime and model cache, so Murmur must stay installed. Override the
voice with the `NARRATE_VOICE` env var (default `af_heart`); usable from any
shell as `echo "hello" | narrate`.
```

- [ ] **Step 2: Verify markdown lints clean**

Run: `npx markdownlint-cli2 docs/nvim-cheatsheet.md 2>&1 | tail -5`
Expected: no MD040 (fenced language), MD034 (bare URL), or MD018 (heading space) errors for the added lines.

- [ ] **Step 3: Commit**

```bash
git add docs/nvim-cheatsheet.md
git commit -m "Document Kokoro/say read-aloud keymaps and narrate CLI"
```

---

## Self-Review

**Spec coverage:**

- Engine Kokoro + Murmur runtime reuse → Task 1 (script uses Murmur venv, `HF_HOME`, Kokoro repo). ✓
- Wrapper script `config/bin/narrate` + `~/.local/bin` symlink + `NARRATE_VOICE` → Task 1. ✓
- `bootstrap.sh` symlink, no installer/Brewfile change → Task 1 Step 7 (only a `link_file`). ✓
- Neovim `<leader>dR`, keep `<leader>dr`, `<leader>ds` stops both → Task 2. ✓
- Error handling (missing runtime, empty input, synthesis failure, temp cleanup) → Task 1 script + Steps 3, 4, 6. ✓
- Docs note (two layers, env var, Murmur dependency) → Task 3. ✓
- Accepted tradeoffs (cold start, Murmur coupling) → reflected as loud failure + docs; no extra task needed (v1 excludes warm-server and uv fallback per spec). ✓

**Placeholder scan:** No TBD/TODO/"handle edge cases"; all code shown in full. ✓

**Type/name consistency:** `narrate_job`, `stop_speech`, `narrate`, `speak`, `visual_selection`, `speech_job` used consistently across Task 2; script flags match the verified mlx-audio 0.4.1 CLI. ✓
