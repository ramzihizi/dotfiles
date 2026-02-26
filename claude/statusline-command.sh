#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract current directory
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Colors (dimmed for statusline)
CYAN='\033[2;36m'
PURPLE='\033[2;35m'
RED='\033[2;31m'
GREEN='\033[2;32m'
YELLOW='\033[2;33m'
DIM='\033[2m'
RESET='\033[0m'

# Directory - truncate to last 2 components like Starship
dir_display=$(echo "$current_dir" | awk -F/ '{if(NF<=3) print $0; else print $(NF-1)"/"$NF}')

output="${CYAN}${dir_display}${RESET}"

# Git info
if cd "$current_dir" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        branch=$(git rev-parse --short HEAD 2>/dev/null)
    fi

    # Git status counts
    status=$(git status --porcelain 2>/dev/null)
    modified=$(echo "$status" | grep -c "^ M\|^MM\|^ D" 2>/dev/null || echo 0)
    staged=$(echo "$status" | grep -c "^M\|^A\|^D\|^R" 2>/dev/null || echo 0)
    untracked=$(echo "$status" | grep -c "^??" 2>/dev/null || echo 0)

    # Ahead/behind
    ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
    behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)

    git_info="${PURPLE} ${branch}${RESET}"

    # Status indicators
    status_str=""
    [ "$modified" -gt 0 ] && status_str+="${RED}!${modified}${RESET}"
    [ "$staged" -gt 0 ] && status_str+="${GREEN}+${staged}${RESET}"
    [ "$untracked" -gt 0 ] && status_str+="${RED}?${untracked}${RESET}"
    [ "$ahead" -gt 0 ] && status_str+="${YELLOW}⇡${ahead}${RESET}"
    [ "$behind" -gt 0 ] && status_str+="${YELLOW}⇣${behind}${RESET}"

    if [ -n "$status_str" ]; then
        git_info+=" ${status_str}"
    fi

    output+=" ${git_info}"
fi

# Language detection
if [ -f "$current_dir/package.json" ]; then
    node_ver=$(node -v 2>/dev/null | tr -d 'v')
    [ -n "$node_ver" ] && output+=" ${GREEN} ${node_ver}${RESET}"
fi

if [ -f "$current_dir/requirements.txt" ] || [ -f "$current_dir/pyproject.toml" ]; then
    py_ver=$(python3 --version 2>/dev/null | awk '{print $2}')
    [ -n "$py_ver" ] && output+=" ${YELLOW} ${py_ver}${RESET}"
fi

if [ -f "$current_dir/go.mod" ]; then
    go_ver=$(go version 2>/dev/null | awk '{print $3}' | tr -d 'go')
    [ -n "$go_ver" ] && output+=" ${CYAN} ${go_ver}${RESET}"
fi

if [ -f "$current_dir/Cargo.toml" ]; then
    rust_ver=$(rustc --version 2>/dev/null | awk '{print $2}')
    [ -n "$rust_ver" ] && output+=" ${RED}󱘗 ${rust_ver}${RESET}"
fi

# Model at the end
output+=" ${DIM}(${model})${RESET}"

printf "%b" "$output"
