# CLAUDE.md

## Rule 0 — Answer first, in plain words

**Above every other rule here. If anything below conflicts with this, this
wins.**

1. **Verdict in sentence one.** A yes/no question gets "yes" or "no" as the
   first word.
2. **Plain words.** English is Ramzi's third language. Jargon and clever
   compression are not brevity.
3. **No menus.** Options only when the choice is genuinely his. Otherwise
   decide, then give the one-line why.
4. **Elaborate only when asked.** Detail earns its place only if it changes
   what he does.

Failure mode: listing tradeoffs when asked for a decision, then burying the
answer under caveats. **If he has to ask twice, the first answer was wrong.**

Conventions for Claude Code when working in this dotfiles repo.

## Markdown formatting

Markdown is formatted by **dprint** — on save in Neovim (via conform) and after
every Write/Edit in this repo via the `.claude/hooks/format-markdown.sh`
PostToolUse hook. Both use the same config (`~/.config/dprint/dprint.json`), so
markdown you write is already formatted: opening it in nvim and saving shows no
diff.

dprint handles these automatically — don't hand-tune them:

- blank lines around headings, lists, and fenced code blocks
- a single trailing newline at end of file
- no trailing whitespace; runs of blank lines collapsed to one

dprint does **not** fix the following, and `markdownlint` flags them in-editor.
Get them right while writing:

- Put a language on every fenced code block (e.g. `bash`, `lua`, `json`,
  `text`) — never an unlabeled fence (markdownlint MD040).
- No bare URLs — write `<https://example.com>` or `[label](https://example.com)`
  (MD034).
- Space after heading hashes: `## Heading`, not `##Heading` (MD018).

Active markdownlint rules live in `config/nvim/.markdownlint.yaml` (line-length
and several stylistic rules are intentionally off).
