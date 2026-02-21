#!/bin/bash
# CloudMotion - Mac Developer Setup (Initial Bootstrap)
#
# Prerequisites (run these first):
#   1. Install Homebrew
#   2. brew install gh
#   3. gh auth login
#   4. gh repo clone CloudMotion/dotfiles ~/dotfiles
#
# Then run: ~/dotfiles/bootstrap-init.sh

set -e

echo "================================================"
echo "  CloudMotion - Mac Developer Setup"
echo "================================================"
echo ""

# Check for macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This script is for macOS only"
    exit 1
fi

DOTFILES_DIR="$HOME/dotfiles"
COMPANY_REPO="CloudMotion/dotfiles"

# Verify prerequisites
echo "==> Checking prerequisites..."

SKIP_BREW=false
SKIP_FORK=false

# Check for Homebrew permission issues (multi-user Mac)
if [[ -d "/opt/homebrew" ]] && [[ ! -w "/opt/homebrew" ]]; then
    echo "    WARNING: /opt/homebrew exists but you don't have write access."
    echo "             Homebrew packages will be skipped."
    echo "             Fix: Ask admin to run: sudo chown -R \$(whoami) /opt/homebrew"
    SKIP_BREW=true
elif ! command -v brew &>/dev/null; then
    echo "    WARNING: Homebrew not installed. Packages will be skipped."
    echo "             Fix: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    SKIP_BREW=true
else
    echo "    Homebrew: OK"
fi

if ! command -v gh &>/dev/null; then
    echo "    WARNING: GitHub CLI not installed. Fork setup will be skipped."
    echo "             Fix: brew install gh"
    SKIP_FORK=true
elif ! gh auth status &>/dev/null; then
    echo "    WARNING: Not authenticated with GitHub. Fork setup will be skipped."
    echo "             Fix: gh auth login"
    SKIP_FORK=true
else
    echo "    GitHub CLI: OK"
fi

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    echo "Error: Dotfiles repo not cloned."
    echo "Run: gh repo clone CloudMotion/dotfiles ~/dotfiles"
    exit 1
fi
echo "    Dotfiles repo: OK"

# Step 1: Set up your personal fork
echo ""
echo "==> Step 1/2: Setting up your personal fork..."

cd "$DOTFILES_DIR"

if [[ "$SKIP_FORK" == "true" ]]; then
    echo "    Skipping fork setup (GitHub CLI not available)"
else
    # Get GitHub username
    GITHUB_USER=$(gh api user --jq '.login')
    echo "    GitHub user: $GITHUB_USER"

    # Check if user already has a fork
    if gh repo view "$GITHUB_USER/dotfiles" &>/dev/null; then
        echo "    Fork already exists: $GITHUB_USER/dotfiles"
    else
        echo "    Creating your personal fork..."
        gh repo fork "$COMPANY_REPO" --clone=false
        echo "    Fork created: $GITHUB_USER/dotfiles"
    fi

    # Update remotes: origin = your fork, upstream = company
    if git remote get-url upstream &>/dev/null; then
        echo "    Remotes already configured."
    else
        echo "    Configuring git remotes..."
        git remote rename origin upstream
        git remote add origin "git@github.com:$GITHUB_USER/dotfiles.git"
        echo "      origin   -> $GITHUB_USER/dotfiles (your fork)"
        echo "      upstream -> $COMPANY_REPO (company repo)"
    fi
fi

# Step 2: Run full setup
echo ""
echo "==> Step 2/2: Installing apps and configuring system..."

SKIP_BREW="$SKIP_BREW" ./bootstrap.sh

echo ""
echo "================================================"
echo "  Setup complete!"
echo "================================================"
echo ""
echo "Your dotfiles are at: ~/dotfiles"
echo "Your fork: github.com/$GITHUB_USER/dotfiles"
echo ""
echo "Next steps:"
echo "  1. Create ~/.gitconfig.local with your name and email"
echo "  2. Restart your terminal"
echo ""
