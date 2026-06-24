#!/bin/bash
# CloudMotion Mac Developer Machine Setup

set -e

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
RESTORE_DIR=""

usage() {
  echo "Usage: ./bootstrap.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --dry-run              Preview changes without applying them"
  echo "  --restore <backup>     Restore from a backup directory"
  echo "  --list-backups         List available backups"
  echo "  --help                 Show this help message"
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --restore) RESTORE_DIR="$2"; shift 2 ;;
    --list-backups)
      echo "Available backups:"
      ls -dt "$HOME"/.dotfiles-backup-* 2>/dev/null || echo "  (none)"
      exit 0
      ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# ============ Restore Mode ============
if [[ -n "$RESTORE_DIR" ]]; then
  if [[ ! -d "$RESTORE_DIR" ]]; then
    echo "Error: Backup directory not found: $RESTORE_DIR"
    echo "Run './bootstrap.sh --list-backups' to see available backups"
    exit 1
  fi

  echo "==> Restoring from: $RESTORE_DIR"
  echo ""

  # Remove symlinks and restore backed-up files
  while IFS= read -r -d '' backup_file; do
    rel="${backup_file#$RESTORE_DIR/}"
    dest="$HOME/$rel"

    # Remove current symlink/file at destination
    if [[ -L "$dest" ]]; then
      rm "$dest"
    elif [[ -e "$dest" ]]; then
      echo "    skipped (not a symlink): $dest"
      continue
    fi

    mv "$backup_file" "$dest"
    echo "    restored: $dest"
  done < <(find "$RESTORE_DIR" -not -type d -print0)

  # Clean up empty backup dirs
  find "$RESTORE_DIR" -type d -empty -delete 2>/dev/null
  rmdir "$RESTORE_DIR" 2>/dev/null && echo "    removed empty backup dir"

  echo ""
  echo "==> Restore complete! Restart your terminal or run: source ~/.zshrc"
  exit 0
fi

# ============ Main Setup ============

# Check for macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This script is for macOS only"
  exit 1
fi

# Verify we're in the dotfiles directory
if [[ ! -f "$DOTFILES_DIR/bootstrap.sh" ]]; then
  echo "Error: Dotfiles not found at ~/dotfiles"
  echo "Run the initial setup first - see README.md"
  exit 1
fi

cd "$DOTFILES_DIR"

if $DRY_RUN; then
  echo "==> DRY RUN - no changes will be made"
  echo ""
fi

echo "==> CloudMotion Mac Dev Setup"
echo ""

# ============ Homebrew ============
if [[ "$SKIP_BREW" == "true" ]]; then
  echo "==> Skipping Homebrew packages (SKIP_BREW is set)"
elif $DRY_RUN; then
  echo "==> Would install Homebrew packages from Brewfile"
else
  if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"

    if ! command -v brew &>/dev/null; then
      echo "Warning: Homebrew installation failed. Skipping packages."
      SKIP_BREW=true
    fi
  fi

  if [[ "$SKIP_BREW" != "true" ]]; then
    echo "==> Installing Homebrew packages (this may take a while)..."
    brew bundle install --file="$DOTFILES_DIR/homebrew/Brewfile"
  fi
fi

# ============ Backup & Link Helpers ============
backup_created=false

backup() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    if ! $backup_created; then
      mkdir -p "$BACKUP_DIR"
      backup_created=true
    fi
    # Preserve directory structure in backup
    local rel="${target#$HOME/}"
    local backup_path="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$backup_path")"
    mv "$target" "$backup_path"
    echo "    backed up: $target"
  fi
}

link_file() {
  local src="$1"
  local dest="$2"

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    echo "    ok (already linked): $dest"
    return
  fi

  if $DRY_RUN; then
    if [[ -e "$dest" || -L "$dest" ]]; then
      echo "    would backup: $dest"
    fi
    echo "    would link: $dest -> $src"
    return
  fi

  backup "$dest"
  ln -sf "$src" "$dest"
  echo "    linked: $dest -> $src"
}

link_dir() {
  local src="$1"
  local dest="$2"

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    echo "    ok (already linked): $dest"
    return
  fi

  if $DRY_RUN; then
    if [[ -e "$dest" || -L "$dest" ]]; then
      echo "    would backup: $dest"
    fi
    echo "    would link: $dest -> $src"
    return
  fi

  backup "$dest"
  ln -sfn "$src" "$dest"
  echo "    linked: $dest -> $src"
}

# ============ Symlink Configurations ============
echo "==> Linking configuration files..."

mkdir -p "$HOME/.config"

# Git
link_file "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/gitignore_global" "$HOME/.gitignore_global"

# Zshrc
link_file "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"

# Starship prompt
link_file "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"

# Kitty
link_dir "$DOTFILES_DIR/config/kitty" "$HOME/.config/kitty"

# WezTerm
link_dir "$DOTFILES_DIR/config/wezterm" "$HOME/.config/wezterm"

# Neovim
link_dir "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"

# Karabiner
link_dir "$DOTFILES_DIR/config/karabiner" "$HOME/.config/karabiner"

# Ghostty
link_dir "$DOTFILES_DIR/config/ghostty" "$HOME/.config/ghostty"

# Gitui
link_dir "$DOTFILES_DIR/config/gitui" "$HOME/.config/gitui"

# Dprint (markdown/code formatter; shared by nvim conform and Claude Code hook)
link_dir "$DOTFILES_DIR/config/dprint" "$HOME/.config/dprint"

# Tmux
link_file "$DOTFILES_DIR/config/tmux/tmux.conf" "$HOME/.tmux.conf"

# Herdr (AI-agent terminal multiplexer; link only config.toml since herdr keeps
# sockets, logs, and session state alongside it in ~/.config/herdr).
mkdir -p "$HOME/.config/herdr"
link_file "$DOTFILES_DIR/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# Pi coding agent (link config-owned directories; pi keeps auth/sessions/settings in ~/.pi/agent)
mkdir -p "$HOME/.pi/agent"
link_file "$DOTFILES_DIR/config/pi/keybindings.json" "$HOME/.pi/agent/keybindings.json"
link_dir "$DOTFILES_DIR/config/pi/extensions" "$HOME/.pi/agent/extensions"
link_dir "$DOTFILES_DIR/config/pi/themes" "$HOME/.pi/agent/themes"

# Claude Code
mkdir -p "$HOME/.claude"
if $DRY_RUN; then
  echo "    would generate: ~/.claude/settings.json"
else
  sed "s|__HOME__|$HOME|g" "$DOTFILES_DIR/claude/settings.json" > "$HOME/.claude/settings.json"
  echo "    generated: ~/.claude/settings.json"
fi
link_file "$DOTFILES_DIR/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link_dir "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
link_dir "$DOTFILES_DIR/claude/hooks" "$HOME/.claude/hooks"

# Claude skills — link each dotfiles-owned skill into ~/.claude/skills, leaving
# plugin-managed skills in place (per-item link, not a whole-dir link).
mkdir -p "$HOME/.claude/skills"
if [[ -d "$DOTFILES_DIR/claude/skills" ]]; then
  for skill_dir in "$DOTFILES_DIR"/claude/skills/*/; do
    [[ -d "$skill_dir" ]] || continue
    link_dir "${skill_dir%/}" "$HOME/.claude/skills/$(basename "$skill_dir")"
  done
fi

# Codex — link only the stable, hand-authored config (hooks + herdr state script).
# NOT config.toml: Codex rewrites it every session (projects/hooks.state/plugin
# install state), so it is machine-local runtime state, not a dotfile.
if [[ -d "$HOME/.codex" ]]; then
  link_file "$DOTFILES_DIR/codex/hooks.json" "$HOME/.codex/hooks.json"
  link_file "$DOTFILES_DIR/codex/herdr-agent-state.sh" "$HOME/.codex/herdr-agent-state.sh"
fi

# OpenCode — config seed (auth lives elsewhere and is not tracked).
mkdir -p "$HOME/.config/opencode"
link_file "$DOTFILES_DIR/config/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"

# narrate (Kokoro read-aloud CLI; reuses Murmur's bundled mlx-audio runtime)
mkdir -p "$HOME/.local/bin"
link_file "$DOTFILES_DIR/config/bin/narrate" "$HOME/.local/bin/narrate"

# ============ Runtime Installers ============
# Install NVM if not present
if [[ ! -d "$HOME/.nvm" ]]; then
  if $DRY_RUN; then
    echo "==> Would install NVM"
  else
    echo "==> Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
fi

# Install Node LTS via NVM if no Node version exists yet.
# Required by Mason for npm-based LSP servers (jsonls, vtsls, tailwindcss, etc.)
# and tools like markdownlint-cli2.
if [[ ! -d "$HOME/.nvm/versions/node" ]] || [[ -z "$(ls -A "$HOME/.nvm/versions/node" 2>/dev/null)" ]]; then
  if $DRY_RUN; then
    echo "==> Would install Node LTS via NVM"
  else
    export NVM_DIR="$HOME/.nvm"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
      echo "==> Installing Node LTS via NVM..."
      # shellcheck disable=SC1091
      . "$NVM_DIR/nvm.sh"
      nvm install --lts
    else
      echo "    (nvm.sh not found; skipping Node — run 'nvm install --lts' manually)"
    fi
  fi
fi

# Install Claude Code CLI if not present (installs to ~/.local/bin/claude)
if ! command -v claude &>/dev/null && [[ ! -x "$HOME/.local/bin/claude" ]]; then
  if $DRY_RUN; then
    echo "==> Would install Claude Code CLI"
  else
    echo "==> Installing Claude Code CLI..."
    curl -fsSL https://claude.ai/install.sh | bash || \
      echo "    (Claude install failed; install manually from https://claude.ai/install.sh)"
  fi
fi

# Install TPM (Tmux Plugin Manager) and its plugins if not present
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  if $DRY_RUN; then
    echo "==> Would install TPM (Tmux Plugin Manager) and plugins"
  else
    echo "==> Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
fi

# Auto-install tmux plugins so tmux works out of the box on a fresh clone
if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
  if $DRY_RUN; then
    echo "==> Would install/update tmux plugins via TPM"
  else
    echo "==> Installing tmux plugins via TPM..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || \
      echo "    (TPM install_plugins exited non-zero; run 'prefix + I' inside tmux to retry)"
  fi
fi

# ============ Summary ============
echo ""
if $DRY_RUN; then
  echo "==> Dry run complete. Run without --dry-run to apply changes."
else
  if $backup_created; then
    echo "==> Backups saved to: $BACKUP_DIR"
  fi
  echo "==> Setup complete!"

  # Show next steps only if local files are missing
  if [[ ! -f "$HOME/.gitconfig.local" ]] || [[ ! -f "$HOME/.zshrc.local" ]]; then
    echo ""
    echo "Next steps:"
    if [[ ! -f "$HOME/.gitconfig.local" ]]; then
      echo "  - Create ~/.gitconfig.local with your name and email:"
      echo "    [user]"
      echo "        name = Your Name"
      echo "        email = your.email@cloudmotion.com"
    fi
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
      echo "  - Create ~/.zshrc.local for machine-specific settings"
    fi
  fi
  echo ""
  echo "Restart your terminal or run: source ~/.zshrc"
fi
echo ""
