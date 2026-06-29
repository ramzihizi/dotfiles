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
  -- Diagnostics: markdownlint-cli2, resolving the NEAREST project rule file.
  --
  -- markdownlint-cli2 lints over stdin and never auto-discovers a project
  -- config (it resolves from cwd, not the file path), so we pass --config
  -- explicitly. Make it dynamic: walk up from the file being linted to the
  -- nearest .markdownlint(.yaml/.json/-cli2.*) so prose projects can carry
  -- their own rules (e.g. ~/bsdn/rmh-wiki and ~/novels/star-rays each loosen
  -- the stylistic rules). Fall back to our global rule file for everything
  -- else — including dotfiles markdown, which finds this very file walking up
  -- to ~/.config/nvim/.markdownlint.yaml.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          -- nvim-lint evaluates each arg element, so the config path can be a
          -- function resolved per-lint against the current buffer's location.
          args = {
            "--config",
            function()
              local names = {
                ".markdownlint.yaml",
                ".markdownlint.yml",
                ".markdownlint.json",
                ".markdownlint.jsonc",
                ".markdownlint-cli2.yaml",
                ".markdownlint-cli2.jsonc",
              }
              local name = vim.api.nvim_buf_get_name(0)
              local start = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
              local found = vim.fs.find(names, { path = start, upward = true, limit = 1 })[1]
              return found or (vim.fn.stdpath("config") .. "/.markdownlint.yaml")
            end,
            "-",
          },
        },
      },
    },
  },

  -- Rendering: tame render-markdown.nvim (pulled in by the LazyVim markdown
  -- extra). Its defaults are busy — full-window-width heading bars, full-width
  -- filled code-block slabs, and sign-column glyphs. Strip those back to a
  -- minimal look while keeping gruvbox colors: both headings and code blocks
  -- render as plain syntax-highlighted text — no background slabs, no border
  -- rules, no gutter glyphs, no floating language-label bar. Foreground
  -- highlights (RenderMarkdownH1..H6) are left alone, so heading colors still
  -- track the colorscheme; the code language (e.g. "bash") shows as quiet text.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,
    opts = {
      heading = {
        sign = false, -- no gutter glyph
        position = "inline", -- icon inlined on the left, not overlaying the '#'s
        backgrounds = {}, -- drop the full-width colored bars; keep foregrounds
      },
      code = {
        sign = false, -- no gutter glyph
        disable_background = true, -- no filled slab behind code blocks
        border = "none", -- no top/bottom rule lines
        language_border = "", -- drop the block-char fill behind the language label
        language_left = "", -- no left edge decoration on the label
        language_right = "", -- no right edge decoration on the label
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
