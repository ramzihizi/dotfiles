# Tmux Cheatsheet

Prefix key: `Ctrl + b`

## Sessions

| Key | Action |
|-----|--------|
| `tmux new -s name` | Create named session (from shell) |
| `tmux ls` | List sessions (from shell) |
| `tmux a -t name` | Attach to session (from shell) |
| `prefix + d` | Detach from session |
| `prefix + s` | List/switch sessions (press `O` to sort by name) |
| `prefix + $` | Rename session |
| `prefix + (` | Previous session |
| `prefix + )` | Next session |
| `:kill-session` | Kill current session |

## Windows

| Key | Action |
|-----|--------|
| `prefix + c` | Create new window |
| `prefix + ,` | Rename window |
| `prefix + &` | Close window |
| `prefix + w` | List all windows |
| `prefix + n` | Next window |
| `prefix + p` | Previous window |
| `prefix + 0-9` | Switch to window by number |

## Panes — Splitting (Custom)

| Key | Action |
|-----|--------|
| `prefix + \|` | Split horizontally (side by side) |
| `prefix + -` | Split vertically (top/bottom) |

## Panes — Navigation (Custom)

| Key | Action |
|-----|--------|
| `prefix + h` | Move to left pane |
| `prefix + j` | Move to pane below |
| `prefix + k` | Move to pane above |
| `prefix + l` | Move to right pane |
| `Ctrl + h/j/k/l` | Navigate panes seamlessly (vim-tmux-navigator) |

## Panes — Resizing (Custom)

| Key | Action |
|-----|--------|
| `prefix + H` | Resize left (5 units) |
| `prefix + J` | Resize down (5 units) |
| `prefix + K` | Resize up (5 units) |
| `prefix + L` | Resize right (5 units) |
| `prefix + m` | Toggle zoom (maximize/restore pane) |

## Copy Mode (Vi Keys)

Enter copy mode with `prefix + [`

| Key | Action |
|-----|--------|
| `v` | Start selection |
| `y` | Copy selection |
| `q` | Exit copy mode |
| `h/j/k/l` | Navigate |
| `/` | Search forward |
| `?` | Search backward |
| `n / N` | Next / previous match |

## Plugins

### TPM (Plugin Manager)

| Key | Action |
|-----|--------|
| `prefix + I` | Install plugins |
| `prefix + U` | Update plugins |
| `prefix + alt + u` | Remove unused plugins |

### Resurrect & Continuum

| Key | Action |
|-----|--------|
| `prefix + Ctrl + s` | Save session (resurrect) |
| `prefix + Ctrl + r` | Restore session (resurrect) |
| (automatic) | Auto-save every 15 min (continuum) |
| (automatic) | Auto-restore on tmux start (continuum) |

## Config

| Key | Action |
|-----|--------|
| `prefix + r` | Reload tmux.conf |

## Command Mode

Enter with `prefix + :`

| Command | Action |
|---------|--------|
| `list-keys` | Show all keybindings |
| `list-sessions` | List sessions |
| `swap-window -t N` | Swap current window with window N |
| `move-window -t N` | Move current window to position N |
| `swap-pane -D / -U` | Swap pane down / up |
