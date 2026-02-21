# CloudMotion Mac Dev Setup

# ============ Aliases ============
# Navigation
alias ..="cd .."
alias ...="cd ../.."

# Git shortcuts
alias gst="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gco="git checkout"

# Safety
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Zsh reload
alias zsr="source ~/.zshrc"

# ============ Functions ============
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ============ History ============
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# ============ Completions ============
autoload -Uz compinit
compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select

# ============ Environment ============
export EDITOR='code'
export VISUAL='code'

# ============ Tool Initialization ============
# Homebrew (if installed)
[[ -x "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# NVM for Node versions (if installed)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ============ Local Overrides ============
# Source local config for machine-specific settings and secrets
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
