# WezTerm Cheatsheet

WezTerm replaces kitty as the terminal emulator and can also multiplex
(panes/tabs/workspaces) for non-agent work. Config:
`~/.config/wezterm/wezterm.lua` (auto-reloads on save).

For AI-agent work the multiplexer is **herdr**, which runs inside wezterm
and keeps tmux's `Ctrl + b` prefix. So wezterm's leader is **`Ctrl + a`** to
stay out of herdr's way. Mapping of tmux concepts → WezTerm:

| tmux    | WezTerm   |
| ------- | --------- |
| session | workspace |
| window  | tab       |
| pane    | pane      |

## Workspaces (tmux sessions)

| Key          | Action                                             |
| ------------ | -------------------------------------------------- |
| `leader + s` | List / switch workspaces (fuzzy launcher)          |
| `leader + w` | Create + switch to a named workspace (tmux new -s) |
| `leader + $` | Rename current workspace                           |
| `leader + d` | Detach from the mux domain                         |
| `wezterm ls` | List mux clients/workspaces (from shell)           |

## Tabs (tmux windows)

| Key            | Action                   |
| -------------- | ------------------------ |
| `leader + c`   | New tab                  |
| `leader + ,`   | Rename tab               |
| `leader + &`   | Close tab (with confirm) |
| `leader + n`   | Next tab                 |
| `leader + p`   | Previous tab             |
| `leader + 1-9` | Switch to tab by number  |

## Panes — Splitting

| Key           | Action                            |
| ------------- | --------------------------------- |
| `leader + \|` | Split horizontally (side by side) |
| `leader + -`  | Split vertically (top / bottom)   |
| `leader + x`  | Close current pane (with confirm) |

## Panes — Navigation

| Key                | Action                                                               |
| ------------------ | -------------------------------------------------------------------- |
| `leader + h/j/k/l` | Move to pane left / down / up / right                                |
| `Ctrl + h/j/k/l`   | Navigate panes seamlessly, hands off to Neovim splits (smart-splits) |

## Panes — Resizing & Zoom

| Key                         | Action                                                          |
| --------------------------- | --------------------------------------------------------------- |
| `leader + r` then `h/j/k/l` | Enter resize mode, resize 5 units (repeatable; `Esc`/`q` exits) |
| `Alt + h/j/k/l`             | Resize pane directly (smart-splits)                             |
| `leader + m` / `leader + z` | Toggle zoom (maximize / restore pane)                           |

## Copy Mode (Vi Keys)

Enter copy mode with `leader + [`

| Key         | Action                  |
| ----------- | ----------------------- |
| `v`         | Start selection         |
| `y`         | Copy selection and exit |
| `q` / `Esc` | Exit copy mode          |
| `h/j/k/l`   | Navigate                |
| `/`         | Search forward          |
| `?`         | Search backward         |
| `n / N`     | Next / previous match   |

Mouse selection copies automatically (no config needed).

## Opacity (ported from kitty)

| Key                     | Action                 |
| ----------------------- | ---------------------- |
| `Ctrl+Shift+a` then `m` | Increase opacity +0.1  |
| `Ctrl+Shift+a` then `l` | Decrease opacity -0.1  |
| `Ctrl+Shift+a` then `1` | Fully opaque           |
| `Ctrl+Shift+a` then `d` | Reset to default (0.9) |
| `Esc` / `q`             | Exit opacity mode      |

## Misc

| Key               | Action                                                   |
| ----------------- | -------------------------------------------------------- |
| `Cmd+Shift+r`     | Speak selected text via macOS `say`                      |
| `leader + Ctrl+a` | Send a literal `Ctrl+a` to the shell (beginning-of-line) |
| `Ctrl+Shift+l`    | Show debug overlay / Lua REPL                            |
| `Ctrl+Shift+p`    | Command palette (search every action)                    |

Config reloads automatically on save — there is no reload keybinding to press.

## Neovim integration

`Ctrl + h/j/k/l` seamless navigation needs **smart-splits.nvim** in Neovim
(it replaces `vim-tmux-navigator`, which only spoke tmux). Add to LazyVim:

```lua
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  keys = {
    { "<C-h>", function() require("smart-splits").move_cursor_left() end },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end },
  },
}
```

Until that's added, `Ctrl + h/j/k/l` still moves between WezTerm panes; it
just won't hand off into Neovim splits.

## Sessions across reboots

WezTerm does not auto-save/restore sessions the way `tmux-resurrect` +
`tmux-continuum` did. For that, add the [resurrect.wezterm](https://github.com/MLFlexer/resurrect.wezterm)
plugin. The local mux server keeps sessions alive while WezTerm is open even
if all windows are closed; a full quit / reboot loses them without the plugin.

## CLI

| Command                | Action                                 |
| ---------------------- | -------------------------------------- |
| `wezterm`              | Launch the GUI                         |
| `wezterm ls`           | List mux clients                       |
| `wezterm cli list`     | List tabs/panes (inside a session)     |
| `wezterm connect unix` | Attach to the local mux server         |
| `wezterm show-keys`    | Print the full active keybinding table |
