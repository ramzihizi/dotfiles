# CloudMotion - Mac Developer Setup

Standard development environment for Mac machines.

## Prerequisites

- macOS (Apple Silicon)
- Admin access to install software
- GitHub account with access to this repo

## Setup

Open Terminal and run these commands:

### 1. Install Homebrew (important)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, run the `eval` command shown in the output to add Homebrew to your PATH.

### 2. Install GitHub CLI

```bash
brew install gh
```

### 3. Authenticate with GitHub

```bash
gh auth login
```

When prompted:

- Select **GitHub.com**
- Select **SSH** (recommended)
- Select **Yes** to generate a new SSH key
- Enter a passphrase (or leave blank)

### 4. Run Setup

```bash
gh repo clone CloudMotion/dotfiles ~/dotfiles
~/dotfiles/bootstrap-init.sh
```

This will:

- Create your personal fork of the dotfiles repo
- Install all apps and tools
- Configure your shell and git

### After Setup: Configure Git Identity

Create `~/.gitconfig.local`:

```bash
nano ~/.gitconfig.local   # or: vi ~/.gitconfig.local
```

Add your details:

```ini
[user]
    name = Your Name
    email = your.email@tcwglobal.com
```

**nano**: Save with `Ctrl+O`, `Enter`, then exit with `Ctrl+X`
**vi**: Press `i` to edit, `Esc` when done, then `:wq` to save and exit

### Install Browser Extensions

Install manually from Chrome Web Store:

- [LastPass](https://chrome.google.com/webstore/detail/lastpass/hdokiejnpimakedhajhdlcegeplioahd)

---

## What's Installed

### CLI Tools

| Tool    | Purpose            |
| ------- | ------------------ |
| git     | Version control    |
| gh      | GitHub CLI         |
| doppler | Secrets management |

### Languages & Runtimes

| Tool           | Purpose                 |
| -------------- | ----------------------- |
| PHP + Composer | PHP development         |
| uv             | Python package manager  |
| NVM            | Node.js version manager |

### Applications

| Category      | Apps                 |
| ------------- | -------------------- |
| Browsers      | Arc, Chrome, Brave   |
| Editors       | VS Code              |
| Terminals     | Ghostty              |
| Communication | Slack, Teams         |
| Office        | Microsoft Office     |
| DevOps        | Orbstack (Docker)    |
| Design        | Figma                |
| Productivity  | Linear, Miro         |
| Utilities     | AppCleaner, Caffeine |

## Updating

Pull latest company changes and re-run the setup:

```bash
cd ~/dotfiles
git fetch upstream
git merge upstream/main
./bootstrap.sh
```

## Customization

### Option 1: Local Overrides (Simple)

For machine-specific settings, create `~/.zshrc.local`:

```bash
# Add your custom aliases, exports, tokens here
export MY_API_KEY="..."
```

This file is not tracked by git.

### Option 2: Customize Your Fork

The setup automatically creates a personal fork for you. To customize:

#### 1. Make your changes

```bash
cd ~/dotfiles
```

Edit any files you want:

- `homebrew/Brewfile` - add your own apps
- `zshrc` - add your own aliases
- `gitconfig` - add your own git settings

#### 2. Commit and push to your fork

```bash
git add -A
git commit -m "My customizations"
git push origin main
```

#### 3. Pull company updates

When the company updates the base dotfiles:

```bash
cd ~/dotfiles
git fetch upstream
git merge upstream/main
git push origin main
```

If there are conflicts, resolve them and commit.

#### 4. Apply changes to your machine

After any updates:

```bash
./bootstrap.sh
```

## Repository Structure

```
dotfiles/
├── bootstrap-init.sh      # Initial setup (run once after cloning)
├── bootstrap.sh           # Full setup script
├── homebrew/
│   └── Brewfile           # All packages and apps
├── zshrc                  # Shell configuration
├── gitconfig              # Git settings
└── gitignore_global       # Global ignore patterns
```

## Troubleshooting

### Homebrew issues

```bash
brew doctor
```

### Reset shell config

```bash
source ~/.zshrc
```

### Re-run setup

```bash
cd ~/dotfiles && ./bootstrap.sh
```

## Support

Contact the engineering team for help with setup issues.
