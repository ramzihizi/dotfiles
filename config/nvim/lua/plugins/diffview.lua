-- diffview.nvim — side-by-side multi-file diffs, file/branch history, ref compare.
-- Complements (does not replace) gitsigns (inline hunks) and lazygit (<leader>gg).
-- All keymaps live under the dedicated <leader>gv subgroup to avoid colliding
-- with LazyVim's already-crowded <leader>g namespace.
return {
  "sindrets/diffview.nvim",
  -- Lazy-load on the commands we map below — zero startup cost.
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewFileHistory",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
  },
  keys = {
    { "<leader>gv", "", desc = "+diffview" },
    { "<leader>gvv", "<cmd>DiffviewOpen<cr>", desc = "Open (working changes)" },
    { "<leader>gvh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
    { "<leader>gvH", "<cmd>DiffviewFileHistory<cr>", desc = "File History (repo)" },
    { "<leader>gvb", "<cmd>DiffviewOpen origin/main...HEAD<cr>", desc = "Compare vs main" },
    { "<leader>gvc", "<cmd>DiffviewClose<cr>", desc = "Close" },
  },
  opts = {
    enhanced_diff_hl = true, -- richer intra-line highlighting
  },
}
