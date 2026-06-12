return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>fa",
        LazyVim.pick("files", { hidden = true, ignored = true }),
        desc = "Find All Files (Root Dir)",
      },
      {
        "<leader>fA",
        LazyVim.pick("files", { root = false, hidden = true, ignored = true }),
        desc = "Find All Files (cwd)",
      },
      {
        "<leader>sA",
        LazyVim.pick("live_grep", { hidden = true, ignored = true }),
        desc = "Grep All Files (Root Dir)",
      },
      {
        "<leader>sF",
        LazyVim.pick("live_grep", { root = false, hidden = true, ignored = true }),
        desc = "Grep All Files (cwd)",
      },
    },
  },
}
