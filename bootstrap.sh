#!/bin/bash
# CloudMotion Mac Developer Machine Setup

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "==> CloudMotion Mac Dev Setup"
echo ""

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

# Install Homebrew packages (unless skipped)
if [[ "$SKIP_BREW" == "true" ]]; then
  echo "==> Skipping Homebrew packages (SKIP_BREW is set)"
else
  # Install Homebrew if needed
  if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # Verify brew is now available
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

# Create config directory
mkdir -p "$HOME/.config"

# Symlink configurations
echo "==> Linking configuration files..."

# Git
ln -sf "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/gitignore_global" "$HOME/.gitignore_global"

# Zshrc
ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"

# Install NVM if not present
if [[ ! -d "$HOME/.nvm" ]]; then
  echo "==> Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

echo ""
echo "==> Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Create ~/.gitconfig.local with your name and email:"
echo "     [user]"
echo "         name = Your Name"
echo "         email = your.email@cloudmotion.com"
echo ""
echo "  2. Create ~/.zshrc.local for any machine-specific settings"
echo ""
echo "  3. Restart your terminal or run: source ~/.zshrc"
echo ""
