-- devdocs.nvim — offline DevDocs.io documentation, browsed in markdown buffers
-- via the snacks picker (it routes through vim.ui.select, which snacks owns).
-- Fast, authoritative, no network round-trip or LLM latency while coding.
--
-- Needs `jq`, `curl`, `pandoc` on PATH (all present). Docs in `ensure_installed`
-- download on first use (lazy-loaded — no startup cost). Install more anytime
-- with <leader>fdi.
--
-- Keymaps live under <leader>fd ("find docs") — a free, mnemonic slot in the
-- LazyVim find group, no collisions.
return {
  "maskudo/devdocs.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = "DevDocs",
  keys = {
    { "<leader>fd", "", desc = "+devdocs" },
    { "<leader>fdd", "<cmd>DevDocs get<cr>", desc = "Open Doc" },
    { "<leader>fdi", "<cmd>DevDocs install<cr>", desc = "Install Doc" },
    { "<leader>fdx", "<cmd>DevDocs delete<cr>", desc = "Delete Doc" },
    { "<leader>fdf", "<cmd>DevDocs fetch<cr>", desc = "Fetch Metadata" },
  },
  opts = {
    -- Pre-seed docs that match this setup's stack. Downloaded on first invoke.
    ensure_installed = {
      "javascript",
      "typescript",
      "css",
      "html",
      "lua~5.1",
    },
  },
}
