# Neovim (LazyVim) Cheatsheet

Leader key: `Space`

## General

| Key | Action |
|-----|--------|
| `Space` | Open which-key menu (shows all leader bindings) |
| `:w` | Save |
| `:q` | Quit |
| `:wq` / `ZZ` | Save and quit |
| `u` | Undo |
| `Ctrl + r` | Redo |
| `.` | Repeat last change |

## Leader Menu Groups

| Key | Group |
|-----|-------|
| `<leader>b` | Buffer |
| `<leader>c` | Code |
| `<leader>d` | Debug |
| `<leader>f` | File/Find |
| `<leader>g` | Git |
| `<leader>gh` | Git hunks |
| `<leader>q` | Quit/Session |
| `<leader>s` | Search |
| `<leader>u` | UI toggles |
| `<leader>w` | Windows |
| `<leader>x` | Diagnostics/Quickfix |
| `<leader><tab>` | Tabs |

## File/Find

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files (root dir) |
| `<leader>fF` | Find files (cwd) |
| `<leader>fr` | Recent files |
| `<leader>fn` | New file |
| `<leader>e` | Explorer (neo-tree) |

## Search

| Key | Action |
|-----|--------|
| `<leader>sg` | Live grep (root dir) |
| `<leader>sG` | Live grep (cwd) |
| `<leader>sw` | Search word under cursor |
| `<leader>sb` | Search in current buffer |
| `<leader>sh` | Help pages |
| `<leader>sk` | Keymaps |
| `<leader>sm` | Jump to mark |
| `<leader>sd` | Document diagnostics |
| `<leader>sD` | Workspace diagnostics |
| `<leader>ss` | LSP symbols (document) |
| `<leader>sS` | LSP symbols (workspace) |
| `<leader>s"` | Registers |
| `<leader>sc` | Command history |
| `<leader>sR` | Resume last search |

## Buffers

| Key | Action |
|-----|--------|
| `<leader>bb` | Switch buffer |
| `<leader>bd` | Delete buffer |
| `<leader>bo` | Delete other buffers |
| `[b` / `]b` | Previous / next buffer |
| `S-h` / `S-l` | Previous / next buffer |

## Windows

| Key | Action |
|-----|--------|
| `<leader>w` | Window menu (proxies Ctrl-w) |
| `Ctrl + h/j/k/l` | Navigate windows (vim-tmux-navigator) |
| `<leader>-` | Split below |
| `<leader>\|` | Split right |
| `<leader>wd` | Close window |

## LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | References |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `gD` | Go to declaration |
| `K` | Hover documentation |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename |
| `<leader>cf` | Format |
| `<leader>cd` | Line diagnostics |
| `<leader>cs` | Symbols (Trouble) |
| `<leader>cS` | LSP references/definitions (Trouble) |

## Diagnostics / Trouble

| Key | Action |
|-----|--------|
| `<leader>xx` | Toggle diagnostics (Trouble) |
| `<leader>xX` | Buffer diagnostics (Trouble) |
| `<leader>xL` | Location list (Trouble) |
| `<leader>xQ` | Quickfix list (Trouble) |
| `[d` / `]d` | Previous / next diagnostic |
| `[q` / `]q` | Previous / next quickfix item |

## Git

| Key | Action |
|-----|--------|
| `<leader>gg` | Open Lazygit |
| `<leader>gf` | Lazygit current file |
| `<leader>gs` | Git status |
| `<leader>gb` | Git blame line |
| `<leader>ghp` | Preview hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghS` | Stage buffer |
| `<leader>ghu` | Undo stage hunk |
| `[h` / `]h` | Previous / next hunk |

## Git Blame (git-blame.nvim)

Inline blame is shown automatically on every line with author, date, summary, and SHA.

| Command | Action |
|---------|--------|
| `:GitBlameToggle` | Toggle inline blame |
| `:GitBlameEnable` | Enable inline blame |
| `:GitBlameDisable` | Disable inline blame |

## Snacks Picker

| Key | Action |
|-----|--------|
| `Ctrl + j` / `Ctrl + k` | Navigate list up/down |
| `Ctrl + u` / `Ctrl + d` | Scroll preview up/down |
| `Alt + w` | Cycle focus: input -> list -> preview |
| `Tab` | Multi-select item |
| `Enter` | Confirm selection |
| `Esc` | Cancel |
| `/` | Toggle focus (from list) |
| `i` | Focus input (from preview) |

## Twilight

| Command | Action |
|---------|--------|
| `:Twilight` | Toggle twilight (dims inactive code) |
| `:TwilightEnable` | Enable twilight |
| `:TwilightDisable` | Disable twilight |

## UI Toggles

| Key | Action |
|-----|--------|
| `<leader>uf` | Toggle format on save |
| `<leader>us` | Toggle spelling |
| `<leader>uw` | Toggle word wrap |
| `<leader>ul` | Toggle line numbers |
| `<leader>ud` | Toggle diagnostics |
| `<leader>uc` | Toggle conceal |
| `<leader>uh` | Toggle inlay hints |

## Navigation — Vim Basics

| Key | Action |
|-----|--------|
| `h/j/k/l` | Left / down / up / right |
| `w / b` | Next / previous word |
| `e` | End of word |
| `0 / $` | Start / end of line |
| `gg / G` | Top / bottom of file |
| `Ctrl + d / u` | Half-page down / up |
| `{ / }` | Previous / next paragraph |
| `%` | Jump to matching bracket |
| `f{char}` / `F{char}` | Jump to next / previous char |
| `*` / `#` | Search word under cursor forward / backward |

## Editing — Vim Basics

| Key | Action |
|-----|--------|
| `i / a` | Insert before / after cursor |
| `I / A` | Insert at start / end of line |
| `o / O` | New line below / above |
| `dd` | Delete line |
| `yy` | Yank (copy) line |
| `p / P` | Paste after / before |
| `ci{` / `ca{` | Change inside / around braces |
| `di{` / `da{` | Delete inside / around braces |
| `>>` / `<<` | Indent / de-indent |
| `gcc` | Toggle comment (line) |
| `gc` (visual) | Toggle comment (selection) |

## Surround

| Key | Action |
|-----|--------|
| `gsa{char}` | Add surround |
| `gsd{char}` | Delete surround |
| `gsr{old}{new}` | Replace surround |
