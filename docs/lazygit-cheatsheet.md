# Lazygit Cheatsheet

## Global

| Key | Action |
|-----|--------|
| `?` | Open keybindings menu |
| `q` | Quit |
| `P` | Push |
| `p` | Pull |
| `R` | Refresh |
| `z` / `Z` | Undo / redo (via reflog) |
| `:` | Execute shell command |
| `+` / `_` | Next / previous screen mode |
| `/` | Search current view |
| `[` / `]` | Previous / next tab |

## Files Panel

| Key | Action |
|-----|--------|
| `Space` | Stage / unstage file |
| `a` | Stage / unstage all |
| `c` | Commit staged changes |
| `A` | Amend last commit |
| `w` | Commit without pre-commit hook |
| `C` | Commit with git editor |
| `s` | Stash all changes |
| `S` | Stash options |
| `d` | Discard options |
| `D` | Reset working tree |
| `e` | Edit file in editor |
| `o` | Open file in default app |
| `i` | Ignore / exclude file |
| `` ` `` | Toggle flat / tree view |

## Staging View (Main Panel)

| Key | Action |
|-----|--------|
| `Space` | Stage / unstage line or hunk |
| `a` | Toggle line vs hunk mode |
| `v` | Toggle range select |
| `d` | Discard selected lines |
| `<left>` / `<right>` | Previous / next hunk |
| `<tab>` | Switch staged / unstaged view |
| `<esc>` | Return to files panel |

## Branches

| Key | Action |
|-----|--------|
| `Space` | Checkout branch |
| `n` | New branch |
| `c` | Checkout by name |
| `-` | Checkout previous branch |
| `d` | Delete branch |
| `r` | Rebase onto branch |
| `M` | Merge into current |
| `f` | Fast-forward |
| `R` | Rename branch |
| `u` | Upstream options |
| `o` | Create pull request |
| `Enter` | View commits |

## Commits

| Key | Action |
|-----|--------|
| `e` | Edit commit (interactive rebase) |
| `i` | Start interactive rebase |
| `r` | Reword commit |
| `s` | Squash into commit below |
| `f` | Fixup into commit below |
| `F` | Create fixup commit |
| `S` | Apply fixup commits (autosquash) |
| `d` | Drop commit |
| `p` | Pick commit (during rebase) |
| `t` | Revert commit |
| `T` | Tag commit |
| `A` | Amend with staged changes |
| `<c-j>` / `<c-k>` | Move commit down / up |
| `Space` | Checkout commit |
| `n` | New branch from commit |
| `C` | Cherry-pick commit |
| `V` | Paste cherry-picked commits |
| `g` | Reset to commit |
| `y` | Copy commit attribute |
| `Enter` | View commit files |

## Stash

| Key | Action |
|-----|--------|
| `Space` | Apply stash |
| `g` | Pop stash |
| `d` | Drop stash |
| `n` | New branch from stash |
| `r` | Rename stash |

## Merge Conflicts

| Key | Action |
|-----|--------|
| `Space` | Pick hunk |
| `b` | Pick all hunks |
| `<up>` / `<down>` | Previous / next hunk |
| `<left>` / `<right>` | Previous / next conflict |
| `z` | Undo resolution |
| `e` | Edit in editor |

## Navigation

| Key | Action |
|-----|--------|
| `<pgup>` / `<pgdn>` | Scroll main panel |
| `<shift-j>` / `<shift-k>` | Scroll main panel |
| `,` / `.` | Previous / next page |
| `<` / `>` | Scroll to top / bottom |
| `H` / `L` | Scroll left / right |
| `<tab>` | Switch between panels |
| `0` | Focus main view |
