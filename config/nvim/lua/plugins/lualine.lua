-- Transient read-aloud indicator: shows 🔊 with the engine (Kokoro / say) while
-- narration is active. State is published by the speak()/narrate() functions in
-- config/keymaps.lua via vim.g.tts_active / vim.g.tts_kind, which also force a
-- lualine refresh so the indicator appears and clears promptly.
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections = opts.sections or {}
    opts.sections.lualine_x = opts.sections.lualine_x or {}
    table.insert(opts.sections.lualine_x, 1, {
      function()
        return "🔊 " .. (vim.g.tts_kind or "reading")
      end,
      cond = function()
        return vim.g.tts_active == true
      end,
      color = { fg = "#fabd2f", gui = "bold" }, -- gruvbox bright yellow
    })
  end,
}
