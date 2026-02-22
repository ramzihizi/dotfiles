# Mac Developer Setup

Personal development environment for Mac machines, based on CloudMotion dotfiles.

## Prerequisites

- macOS (Apple Silicon)
- Admin access to install software
- GitHub account

## Quick Setup

```bash
# Clone the repo
git clone git@github.com:ramzihizi/dotfiles.git ~/dotfiles

# Run setup
cd ~/dotfiles && ./bootstrap.sh
```

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

### 3. Install Tmux Plugins

Open tmux and press `prefix + I` to install plugins via TPM.

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
| Terminals | Kitty |
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
