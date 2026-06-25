# Kokoro-in-Neovim narration ("say in reverse, but good")

Date: 2026-06-23

## Goal

Add a high-quality "read this selection aloud" hotkey in Neovim, mirroring the
existing `/usr/bin/say` flow but with a natural-sounding neural voice. Keep the
existing `say` keymap untouched. Reuse the Murmur app's already-installed TTS
runtime and model cache instead of installing or downloading anything new.

This is the local, in-editor counterpart to Murmur: Murmur is the GUI studio for
sit-down / batch / voice-clone narration; this hotkey is for instant feedback
while editing.

## Background: what Murmur already provides

Murmur (purchased 2026-06-23) bundles a self-contained MLX TTS runtime under:

```text
~/Library/Application Support/Murmur/MLXAudioBridge/com.murmur.app/
├── venv/                # 885 MB — Python 3.11, mlx-audio 0.4.1, mlx, misaki, soundfile
├── huggingface/         # HF cache; HF_HOME points here
│   └── hub/models--mlx-community--Qwen3-TTS-12Hz-0.6B-Base-bf16   # 2.4 GB
└── murmur_mlx_bridge.py # Murmur's own server; reads HF_HOME to locate models
```

Verified facts:

- `venv/bin/python -m mlx_audio.tts.generate` imports and runs.
- The Kokoro model **code** ships in the venv
  (`mlx_audio/tts/models/kokoro/kokoro.py`); its **weights** repo is
  `prince-canuma/Kokoro-82M` (~160 MB), fetched on first use into whatever
  `HF_HOME` points at.
- Qwen3-TTS weights (2.4 GB) are already cached; Kokoro weights are not yet.
- The bridge locates models via the `HF_HOME` environment variable.

Because the runtime is a normal venv and model lookup is `HF_HOME`-driven, an
external script can reuse both by invoking that python with `HF_HOME` set to
Murmur's cache.

## Decisions

- **Engine:** Kokoro (`prince-canuma/Kokoro-82M`). Fast and light — right for a
  snappy hotkey. Qwen3-0.6B is heavier/slower and stays Murmur's GUI workhorse.
- **Keymap:** add a new key; keep `say`. `<leader>dr` remains `say`;
  `<leader>dR` is the new Kokoro narration. `<leader>ds` stops both.
- **Playback:** synthesize to a temp WAV, then `afplay`. Reuses the existing
  job/stop pattern and gives clean stop control via `pkill afplay`.
- **Runtime:** piggyback on Murmur's venv + HF cache. No `uv tool install`, no
  Brewfile change, no duplicate runtime or weights.
- **Latency:** accept per-call model load (a few seconds before audio starts).
  Warm-server mode is a documented future upgrade, not in v1.

## Architecture

Two independent layers, both retained:

| Layer         | Tool                      | Job                                             | In dotfiles      |
| ------------- | ------------------------- | ----------------------------------------------- | ---------------- |
| GUI studio    | Murmur                    | sit-down / batch / voice-clone narration → file | no (just an app) |
| Editor hotkey | `narrate` + Neovim keymap | instant "read selection" while editing          | yes              |

### Data flow

```text
visual selection
  → narrate (text on stdin)
    → Murmur venv python -m mlx_audio.tts.generate  (HF_HOME = Murmur cache)
      → temp WAV
        → afplay
          → cleanup temp WAV
```

## Components

### 1. `config/bin/narrate` (new), symlinked to `~/.local/bin/narrate`

Single responsibility: read text on stdin, speak it via Kokoro. Mirrors the
`say` interface so it is usable from any shell (`echo "hello" | narrate`) and
trivially swappable in Neovim.

Behaviour:

- Resolve the Murmur bridge dir:
  `~/Library/Application Support/Murmur/MLXAudioBridge/com.murmur.app`.
- If `venv/bin/python` is missing, print an actionable error to stderr and exit
  non-zero (e.g. "Murmur runtime not found — open Murmur once, or reinstall").
- `export HF_HOME="$BRIDGE/huggingface"`.
- Read all of stdin into a variable; if empty, error and exit non-zero.
- Synthesize to a temp WAV in `$TMPDIR` (unique name) via:
  `"$BRIDGE/venv/bin/python" -m mlx_audio.tts.generate --model prince-canuma/Kokoro-82M --voice "${NARRATE_VOICE:-af_heart}" --text "<stdin>" --file_prefix <tmp-prefix>`
  (exact output-file flag confirmed against `generate.py` at implementation
  time; `--file_prefix` is the candidate, fall back to whatever the installed
  0.4.1 CLI exposes).
- `afplay` the resulting WAV.
- Remove the temp WAV on exit (trap, so it is cleaned even if interrupted).

Configuration via env var:

- `NARRATE_VOICE` — Kokoro voice name, default `af_heart`.

### 2. `bootstrap.sh` (changed)

- Add a `link_file` for `narrate`:
  `link_file "$DOTFILES_DIR/config/bin/narrate" "$HOME/.local/bin/narrate"`
  (ensure `~/.local/bin` exists first; it is already on `PATH`).
- No Runtime-Installer step and no Brewfile change: the runtime comes from
  Murmur. The script self-reports if Murmur's runtime is absent.

### 3. `config/nvim/lua/config/keymaps.lua` (changed)

- Add a `narrate(text)` helper paralleling the existing `speak(text)`: start
  `narrate` via `jobstart`, send text on stdin, close stdin.
- Map `<leader>dR` in visual mode → `narrate(visual_selection())`,
  desc "Read Selection (Kokoro)".
- Extend `stop_speech()` so one stop key covers both engines: also `jobstop`
  the narrate job and `pkill -x afplay`. `<leader>ds` keeps its current binding.
- Keep `<leader>dr` (`say`) exactly as is.

### 4. Docs (changed)

- Short note (in `docs/`, e.g. the nvim cheatsheet) recording: the two-layer
  setup, `<leader>dR` / `<leader>ds`, the `NARRATE_VOICE` env var, and that the
  runtime is borrowed from Murmur (so Murmur must stay installed).

## Error handling

- Murmur runtime missing → `narrate` prints actionable stderr, exits non-zero;
  Neovim helper surfaces it via `vim.notify` at ERROR level.
- Empty selection → handled before spawning (notify WARN), matching `speak`.
- Synthesis failure (non-zero exit) → no `afplay`; error surfaced.
- Temp file always cleaned via shell trap.

## Testing

- Shell: `echo "testing one two three" | narrate` produces audible Kokoro
  speech; temp WAV is removed afterward.
- Shell: `printf '' | narrate` errors cleanly (empty input).
- Shell: with the bridge path temporarily renamed, `narrate` prints the
  actionable "runtime not found" error and exits non-zero.
- Neovim: select text, `<leader>dR` → audible narration; `<leader>ds` stops it;
  `<leader>dr` still uses `say`; `<leader>ds` also stops `say`.

## Known tradeoffs / future work

- **Coupling to Murmur:** `narrate` depends on Murmur's private app folder. If
  Murmur is uninstalled or rebuilds its venv mid-update, `narrate` breaks until
  Murmur is present again. Accepted for v1; the script fails loudly. Optional
  future fallback: prefer Murmur's venv, else a self-owned `uvx mlx-audio`.
- **Cold start:** per-call model load adds a few seconds before audio. Future
  upgrade: run `mlx_audio.server` warm and have `narrate` POST text for
  near-instant playback.
