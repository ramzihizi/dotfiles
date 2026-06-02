#!/bin/bash
# PostToolUse hook: after Claude writes/edits a markdown file, format it with
# dprint using the SAME config Neovim's conform uses
# (~/.config/dprint/dprint.json). This keeps Claude's markdown byte-identical to
# what nvim produces on save, so opening the file and `:w` shows no spurious diff.
#
# dprint owns formatting; markdownlint-cli2 runs only as a Neovim diagnostic
# (see config/nvim/lua/plugins/markdown.lua) and never edits the file, so the
# two can't fight. The few things dprint can't auto-fix (bare URLs, missing
# code-fence languages, "##heading" with no space) are documented in CLAUDE.md.

hook_input=$(cat)
file=$(printf '%s' "$hook_input" | jq -r '.tool_input.file_path // empty')

[ -n "$file" ] || exit 0
case "$file" in
  *.md | *.markdown | *.mdx) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0
command -v dprint >/dev/null 2>&1 || exit 0

# dprint matches file args as globs relative to CWD, so an absolute path is
# "No files found". Run from the file's own directory on its basename instead.
if ! (cd "$(dirname "$file")" && dprint fmt --config "$HOME/.config/dprint/dprint.json" "$(basename "$file")") >/dev/null 2>&1; then
  echo "format-markdown hook: dprint failed to format $file" >&2
fi
exit 0
