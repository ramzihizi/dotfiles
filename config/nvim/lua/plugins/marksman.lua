-- Disable marksman, the markdown LSP.
--
-- marksman is NOT one of our plugin specs — it is pulled in by LazyVim's
-- `lang.markdown` extra (see lazyvim.json), which adds `marksman = {}` to the
-- LSP servers. So deleting a spec file does nothing; the extra re-adds it.
-- LazyVim's documented opt-out is `enabled = false`: the server is skipped at
-- setup AND added to mason-lspconfig's `automatic_enable.exclude`, so the
-- installed mason binary won't auto-start either. The rest of the markdown
-- extra (render-markdown, markdownlint, treesitter) is unaffected.
--
-- Why off: marksman crash-loops while indexing the 1,757-file rmh-wiki Obsidian
-- vault (MailboxProcessor timeouts + transient IO errors -> restart -> full
-- reindex), stalling the editor with typing/file-open lag that grew with the
-- vault. Link navigation/completion now lives in the Obsidian app; Neovim is
-- for quick edits.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      marksman = { enabled = false },
    },
  },
}
