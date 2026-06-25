-- marksman is the single markdown link-LSP for the Obsidian vaults
-- (obsidian.nvim was removed — heavy note work happens in the Obsidian app;
-- Neovim is for quick edits + jumping around).
--
-- By default marksman only roots at `.marksman.toml`/`.git`, so notes in a
-- vault without a git repo never get a workspace and `[[` completion silently
-- breaks (it falls back to single-file mode). Every Obsidian vault has a
-- `.obsidian/` folder at its root, so adding that as a root marker makes
-- marksman attach with the correct per-vault root in ALL vaults — and re-root
-- per buffer automatically — without adding any files to the vaults themselves.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      marksman = {
        root_markers = { ".obsidian", ".marksman.toml", ".git" },
      },
    },
  },
}
