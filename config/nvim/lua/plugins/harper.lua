-- harper-ls — local, privacy-respecting grammar checker (LSP).
-- Pure-Rust, no telemetry, no cloud. Mason installs the `harper-ls` binary
-- automatically because it's listed under lspconfig `servers` below.
--
-- Scoped to prose filetypes only (markdown + git commit messages) so it never
-- lints code comments. Diagnostics are emitted at HINT severity to stay quiet
-- and unobtrusive — bump `diagnosticSeverity` to "information"/"warning" if you
-- want them louder. Use the LSP "add to dictionary" code action (<leader>ca)
-- to teach it wiki jargon and proper nouns.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      harper_ls = {
        filetypes = { "markdown", "gitcommit" },
        settings = {
          ["harper-ls"] = {
            diagnosticSeverity = "hint",
            markdown = {
              ignoreLinkTitle = true, -- don't lint inside [link](titles)
            },
            linters = {
              -- Silence the two most hair-trigger stylistic rules; keep the
              -- substantive grammar/spelling/repeated-word checks on.
              SentenceCapitalization = false,
              LongSentences = false,
            },
          },
        },
      },
    },
  },
}
