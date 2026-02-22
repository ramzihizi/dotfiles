# CloudMotion + Personal Mac Dev Setup

# ============ Zsh Options ============
# setopt AUTO_CD                # cd without typing cd
# setopt AUTO_PUSHD             # Push directories to stack
# setopt PUSHD_IGNORE_DUPS      # No duplicate dirs in stack
# setopt CORRECT                # Spelling correction
# setopt EXTENDED_HISTORY       # Better history
# setopt HIST_IGNORE_ALL_DUPS   # No duplicates in history
# setopt HIST_IGNORE_SPACE      # No commands starting with space
# setopt HIST_REDUCE_BLANKS     # Remove extra blanks
# setopt INC_APPEND_HISTORY     # Add to history immediately
# setopt SHARE_HISTORY          # Share between sessions
# setopt INTERACTIVE_COMMENTS   # Allow comments in interactive

# ============ Aliases ============
# Apps (only alias if command exists)
alias 'c'='clear'
command -v nvim &>/dev/null && alias 'vi'='nvim' && alias 'vim'='nvim'
command -v cursor &>/dev/null && alias 'crs'='cursor'
command -v lazygit &>/dev/null && alias 'lzyg'='lazygit'
command -v lazydocker &>/dev/null && alias 'lzyd'='lazydocker'
command -v lazyjj &>/dev/null && alias 'lzyj'='lazyjj'
command -v windsurf &>/dev/null && alias 'wnd'='windsurf'
command -v claude &>/dev/null && alias 'cld'='claude'
command -v opencode &>/dev/null && alias 'pncd'='opencode'
command -v gemini &>/dev/null && alias 'gmn'='gemini'
command -v codex &>/dev/null && alias 'cdx'='codex'
command -v antigravity &>/dev/null && alias 'ntg'='antigravity'

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Git shortcuts
alias gst="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias glo="git log --oneline --graph"

# Better defaults (only alias if command exists)
command -v eza &>/dev/null && alias ll="eza -la --icons" && alias ls="eza --icons" && alias tree="eza --tree --icons"
command -v bat &>/dev/null && alias cat="bat"
command -v fd &>/dev/null && alias find="fd"
command -v rg &>/dev/null && alias grep="rg"
alias df="df -h"
alias du="du -h"

# Safety
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Zsh reload
alias zsr="source ~/.zshrc"
alias zshr="source ~/.zshrc"
alias zsc="exec zsh -l"

# ============ Functions ============
# Make directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ============ History ============
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# ============ Completions ============
autoload -Uz compinit
compinit

# Better completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select

# ============ Key Bindings ============
# bindkey -v  # -e -> Emacs mode # -v for vim
# bindkey '^[[A' history-search-backward
# bindkey '^[[B' history-search-forward

# ============ Environment ============
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'

# Kitty terminal integration
if [ "$TERM_PROGRAM" = "kitty" ] || [ -n "$KITTY_WINDOW_ID" ]; then
    export TERM="xterm-kitty"
fi

# ============ Tool Initialization ============
# Homebrew
[[ -x "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Starship prompt
command -v starship &>/dev/null && eval "$(starship init zsh)"

# FZF - Set up fzf key bindings and fuzzy completion
if command -v fzf &>/dev/null; then
    source <(fzf --zsh) 2>/dev/null
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fi

# Zoxide (better cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# NVM for Node versions
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ============ Zsh Plugins ============
# zsh-vi-mode (must be loaded before other plugins that bind keys)
[ -f /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh ] && \
    source /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# Syntax highlighting and autosuggestions (must be at the end of plugins)
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ============ Additional Tools ============
# Bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
if [ -d "$HOME/.bun" ]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Carapace completion
if command -v carapace &>/dev/null; then
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    source <(carapace _carapace)
fi

# uv shell completion
command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"

# Windsurf (if installed)
[ -d "$HOME/.codeium/windsurf/bin" ] && export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# Antigravity (if installed)
[ -d "$HOME/.antigravity/antigravity/bin" ] && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# ============ Local Overrides ============
# Source local config for machine-specific settings and secrets
# (Doppler tokens, API keys, etc.)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
