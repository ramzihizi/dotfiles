-- Disable harper_ls, the grammar LSP.
--
-- harper_ls is no longer one of our specs, but the harper-ls binary is still
-- installed in Mason, and mason-lspconfig 2.x runs with automatic_enable = true
-- — it auto-starts EVERY installed mason LSP. So merely deleting our config
-- left harper-ls auto-attaching to markdown buffers (now with its unscoped
-- defaults, worse than the scoped config we removed). `enabled = false` is
-- LazyVim's opt-out: the server is excluded from mason-lspconfig's
-- automatic_enable list, so the installed binary stays inert.
--
-- Grammar checking now lives in the Obsidian app (Harper as an in-app WASM
-- plugin), where the heavy note writing happens. Run `:MasonUninstall
-- harper-ls` to drop the binary entirely if you want zero trace.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      harper_ls = { enabled = false },
    },
  },
}
