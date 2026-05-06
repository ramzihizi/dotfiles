# Mac Developer Setup

Personal development environment for Mac machines, based on CloudMotion dotfiles.

## Prerequisites

Before running the bootstrap script, you must have these installed and configured:

- macOS (Apple Silicon)
- Admin access to install software
- GitHub account
- **Homebrew** — package manager (used to install everything in `homebrew/Brewfile`)
- **GitHub CLI (`gh`)** — used by `bootstrap-init.sh` to fork the repo and configure remotes
- An SSH key uploaded to GitHub (or be authenticated via `gh auth login`)

### Install the prerequisites

```bash
# 1. Install Xcode Command Line Tools (provides git, compilers, etc.)
xcode-select --install

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to your shell PATH (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. Install GitHub CLI and authenticate
brew install gh
gh auth login
```

## Quick Setup

```bash
# Clone the repo (use gh so auth is already handled)
gh repo clone ramzihizi/dotfiles ~/dotfiles
# or, with SSH:
# git clone git@github.com:ramzihizi/dotfiles.git ~/dotfiles

# Run setup
cd ~/dotfiles && ./bootstrap.sh
```

> If you are setting this up at CloudMotion and want a personal fork wired up automatically, run `./bootstrap-init.sh` instead — it forks the company repo, configures `origin`/`upstream`, then calls `bootstrap.sh`.

## After Setup

### 1. Configure Git Identity

Create `~/.gitconfig.local`:

```ini
[user]
    name = Your Name
    email = your.email@example.com
```

### 2. Configure Secrets

Create `~/.zshrc.local` for API keys and tokens:

```bash
# Doppler tokens, API keys, etc.
export DOPPLER_TOKEN="..."
```

### 3. Tmux Plugins

`bootstrap.sh` installs TPM and its plugins automatically. If you ever need to re-install or update plugins manually, open tmux and press `prefix + I` (install) or `prefix + U` (update).

---

## What's Installed

### CLI Tools

| Tool | Purpose |
|------|---------|
| git, gh | Version control & GitHub CLI |
| bat, eza, fd, ripgrep | Modern CLI replacements |
| fzf, zoxide | Fuzzy finder & smart cd |
| jq, tree, tldr | JSON processor, dir tree, simplified man |
| neovim, tmux | Editor & terminal multiplexer |
| lazygit, lazydocker, lazyjj | TUI for git, docker, jujutsu |
| starship | Cross-shell prompt |
| difftastic | Structural diff tool |
| carapace | Multi-shell completion |

### Zsh Plugins

- zsh-vi-mode
- zsh-autosuggestions
- zsh-completions
- zsh-syntax-highlighting

### Languages & Runtimes

| Tool | Purpose |
|------|---------|
| PHP + Composer | PHP development |
| uv | Python package manager |
| NVM | Node.js version manager |
| Bun | Fast JS runtime |
| jj | Jujutsu version control |

### AI Tools

| Tool | Purpose |
|------|---------|
| claude, claude-code | Anthropic Claude |
| cursor | AI-powered code editor |
| codex | OpenAI Codex CLI |
| gemini-cli | Google Gemini CLI |
| opencode | SST OpenCode CLI |
| block-goose-cli | Block Goose AI |

### Applications

| Category | Apps |
|----------|------|
| Browsers | Arc, Chrome, Brave, Zen, Dia |
| Terminals | Ghostty, Kitty, cmux |
| Editors | VS Code, Cursor |
| Communication | Slack, Teams, Zoom |
| Office | Microsoft Office |
| DevOps | Orbstack (Docker) |
| Design | Figma |
| Productivity | Linear, Miro, Obsidian, Raycast |
| Utilities | AppCleaner, Caffeine, Karabiner, VLC |

### Config Files

| Config | Location |
|--------|----------|
| Starship | `~/.config/starship.toml` |
| Ghostty | `~/.config/ghostty/` |
| Kitty | `~/.config/kitty/` |
| Neovim | `~/.config/nvim/` |
| Karabiner | `~/.config/karabiner/` |
| Tmux | `~/.tmux.conf` |

## Repository Structure

```
dotfiles/
├── bootstrap.sh           # Setup script
├── homebrew/
│   └── Brewfile           # All packages and apps
├── config/
│   ├── starship/          # Starship prompt config
│   ├── ghostty/           # Ghostty terminal config
│   ├── kitty/             # Kitty terminal config
│   ├── nvim/              # Neovim (LazyVim) config
│   ├── karabiner/         # Karabiner keyboard config
│   └── tmux/              # Tmux config
├── zshrc                  # Shell configuration
├── gitconfig              # Git settings
└── gitignore_global       # Global ignore patterns
```

## Updating

```bash
cd ~/dotfiles
git pull
./bootstrap.sh
```

## Customization

### Local Overrides

For machine-specific settings, use local files (not tracked by git):

- `~/.gitconfig.local` - Git identity, signing keys
- `~/.zshrc.local` - API keys, tokens, machine-specific settings

### Modify Dotfiles

Edit files directly and push:

```bash
cd ~/dotfiles
# Make changes...
git add -A
git commit -m "Update config"
git push
```

## Safety & Rollback

Bootstrap automatically backs up any existing files before replacing them with symlinks. Backups are saved to `~/.dotfiles-backup-<timestamp>/`.

### Preview before applying

```bash
./bootstrap.sh --dry-run
```

### List available backups

```bash
./bootstrap.sh --list-backups
```

### Restore from a backup

```bash
# See what backups exist
./bootstrap.sh --list-backups

# Restore (replaces symlinks with your original files)
./bootstrap.sh --restore ~/.dotfiles-backup-20260306-120000
```

### What gets backed up

Everything that bootstrap replaces: `~/.zshrc`, `~/.gitconfig`, `~/.gitignore_global`, `~/.config/starship.toml`, `~/.config/kitty/`, `~/.config/ghostty/`, `~/.config/nvim/`, `~/.config/karabiner/`, `~/.tmux.conf`, and Claude Code configs.

Local override files (`~/.gitconfig.local`, `~/.zshrc.local`) are **never touched** by bootstrap.

## Troubleshooting

### Homebrew issues

```bash
brew doctor
```

### Reset shell config

```bash
source ~/.zshrc
# or
exec zsh -l
```

### Re-run setup

```bash
cd ~/dotfiles && ./bootstrap.sh
```

### Tmux behaving weirdly after a fresh clone

If detach/attach is broken or the status bar/theme isn't showing, the most common causes are:

1. TPM plugins were never installed. `bootstrap.sh` now installs them automatically, but if you skipped that step, run:
   ```bash
   ~/.tmux/plugins/tpm/bin/install_plugins
   ```
   Or, inside a tmux session, press `prefix + I`.
2. `tmux-continuum` is auto-restoring a stale session from another machine. Kill all sessions and start fresh:
   ```bash
   tmux kill-server
   ```

### Karabiner-Elements rules not applying

If your Karabiner config is symlinked correctly but key remappings aren't taking effect, the cause is almost always macOS permissions, not the config. Karabiner ships several daemons; the one that actually intercepts keystrokes is `karabiner_grabber`, and it requires per-machine permissions that **do not transfer through dotfiles**.

Diagnose:

```bash
# These three should all be running. If karabiner_grabber is missing, permissions are the issue.
pgrep -lf karabiner
```

Fix:

1. Open **System Settings → Privacy & Security → Input Monitoring** and enable:
   - `karabiner_grabber`
   - `karabiner_observer`
   - `Karabiner-Elements`
2. Open **System Settings → Privacy & Security → Accessibility** and enable `Karabiner-Elements`.
3. Make sure the Virtual HID Device system extension is enabled (System Settings → Privacy & Security → "Allow system software from developer 'Fumihiko Takayama'" if prompted). Verify with:
   ```bash
   systemextensionsctl list | grep -i karabiner
   # should show: [activated enabled]
   ```
4. Quit and relaunch Karabiner-Elements from Spotlight. `karabiner_grabber` should now start.

Verify:

```bash
pgrep -lf karabiner_grabber   # should print a PID
```

### Symlinks not created

If configs aren't linked after running bootstrap.sh, create them manually:

```bash
# Create .config directory
mkdir -p ~/.config

# Create symlinks
ln -sf ~/dotfiles/config/starship/starship.toml ~/.config/starship.toml
ln -sfn ~/dotfiles/config/ghostty ~/.config/ghostty
ln -sfn ~/dotfiles/config/kitty ~/.config/kitty
ln -sfn ~/dotfiles/config/nvim ~/.config/nvim
ln -sfn ~/dotfiles/config/karabiner ~/.config/karabiner
ln -sf ~/dotfiles/config/tmux/tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/zshrc ~/.zshrc
ln -sf ~/dotfiles/gitconfig ~/.gitconfig
ln -sf ~/dotfiles/gitignore_global ~/.gitignore_global

# Reload shell
exec zsh -l
```
