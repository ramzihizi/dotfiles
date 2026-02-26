#!/bin/bash

# Read the hook input from stdin
hook_input=$(cat)

# Extract the bash command from the JSON input
command=$(echo "$hook_input" | jq -r '.tool_input.command')

# Only run prettier if this is a gh pr create command
if [[ "$command" == *"gh pr create"* ]]; then
  echo "Running prettier before PR creation..."

  # Run prettier on staged and modified files
  cd "$CLAUDE_PROJECT_DIR"

  # Format all TypeScript/JavaScript files that might be affected
  if command -v bunx &> /dev/null; then
    bunx prettier --write "**/*.{ts,tsx,js,jsx}" --ignore-unknown 2>/dev/null || true
  elif command -v npx &> /dev/null; then
    npx prettier --write "**/*.{ts,tsx,js,jsx}" --ignore-unknown 2>/dev/null || true
  fi

  echo "Prettier formatting complete"
fi

# Exit 0 = allow the tool call to proceed
exit 0
