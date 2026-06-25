-- typewriter.nvim — keeps the cursor line vertically centered as you write
-- ("typewriter scrolling"). Fills the one focus gap snacks-zen/twilight leave:
-- they dim/center the buffer but don't pin the active line. Aimed at long-form
-- prose (the novel + the wiki).
--
-- Default OFF; flip a writing session on with <leader>uW. To instead make it
-- always-on in prose buffers, add `always_center_filetypes = { "markdown" }`.
return {
  "joshuadanpeterson/typewriter",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  cmd = { "TWToggle", "TWEnable", "TWDisable", "TWCenter", "TWTop", "TWBottom" },
  keys = {
    { "<leader>uW", "<cmd>TWToggle<cr>", desc = "Typewriter (Writing) Mode" },
  },
  opts = {
    keep_cursor_position = true,
    enable_notifications = false,
    enable_with_zen_mode = true, -- no-op with snacks zen, harmless to leave on
  },
}
