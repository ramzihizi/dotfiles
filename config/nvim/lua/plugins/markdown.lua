-- Markdown tooling: dprint formats, markdownlint-cli2 lints (diagnostics only).
--
-- dprint (via conform, below) is the SINGLE source of truth for markdown
-- formatting on save. Claude Code runs the same dprint + config
-- (~/.config/dprint/dprint.json) via a PostToolUse hook, so files Claude writes
-- are already formatted and `:w` produces no diff.
--
-- markdownlint-cli2 runs only as an nvim-lint *diagnostic*. It points at our
-- rule file (~/.config/nvim/.markdownlint.yaml) because markdownlint-cli2 lints
-- over stdin and never auto-discovers a project config. Crucially it is NOT a
-- conform formatter here, so it can't --fix the buffer on save and fight dprint.
return {
  -- Diagnostics: markdownlint-cli2 with our explicit rule file.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = {
            "--config",
            vim.fn.stdpath("config") .. "/.markdownlint.yaml",
            "-",
          },
        },
      },
    },
  },

  -- Formatting: dprint only. Override the LazyVim markdown extra's default
  -- chain (prettier + markdownlint-cli2 + markdown-toc) so a single tool owns
  -- formatting. The opts function runs after the extra's table opts, so direct
  -- assignment here replaces the list rather than appending to it.
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.markdown = { "dprint" }
      opts.formatters_by_ft["markdown.mdx"] = { "dprint" }

      opts.formatters = opts.formatters or {}
      opts.formatters.dprint = {
        prepend_args = { "--config", vim.fn.expand("~/.config/dprint/dprint.json") },
      }
    end,
  },
}
