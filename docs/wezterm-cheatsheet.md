# WezTerm Cheatsheet

WezTerm is the terminal emulator (a kitty replacement) in a **wezterm + tmux**
flow. It does **not** multiplex — tmux owns panes, windows, and sessions via
its `Ctrl + b` prefix. So wezterm binds almost nothing and lets keys like
`Ctrl + h/j/k/l` and `Ctrl + b` pass straight through to tmux.

`Ctrl + h/j/k/l` pane navigation depends on **Karabiner**: a global rule remaps
`Ctrl+hjkl` to arrow keys, and wezterm must be in that rule's exclusion list
(alongside kitty/ghostty) or the keys arrive as literal arrows and never reach
tmux. `enable_kitty_keyboard = true` separately makes wezterm honor the kitty
keyboard protocol like kitty, matching tmux's `extended-keys` handling (for pi).

Config: `~/.config/wezterm/wezterm.lua` (auto-reloads on save — no reload key).

For multiplexing keys see [tmux-cheatsheet.md](tmux-cheatsheet.md).

## Opacity (ported from kitty)

| Key                     | Action                 |
| ----------------------- | ---------------------- |
| `Ctrl+Shift+a` then `m` | Increase opacity +0.1  |
| `Ctrl+Shift+a` then `l` | Decrease opacity -0.1  |
| `Ctrl+Shift+a` then `1` | Fully opaque           |
| `Ctrl+Shift+a` then `d` | Reset to default (0.9) |
| `Esc` / `q`             | Exit opacity mode      |

## Misc

| Key            | Action                                |
| -------------- | ------------------------------------- |
| `Cmd+Shift+r`  | Speak selected text via macOS `say`   |
| `Ctrl+Shift+l` | Show debug overlay / Lua REPL         |
| `Ctrl+Shift+p` | Command palette (search every action) |

Mouse selection copies automatically (no config needed).

## CLI

| Command             | Action                       |
| ------------------- | ---------------------------- |
| `wezterm`           | Launch the GUI               |
| `wezterm show-keys` | Print the active keybindings |
