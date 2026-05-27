-- Tame markdownlint warnings.
-- The LazyVim markdown extra lints with markdownlint-cli2 over stdin, so it
-- never auto-discovers a project config. Point it explicitly at our rule file
-- (~/.config/nvim/.markdownlint.yaml, tracked in dotfiles) instead.
return {
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
}
