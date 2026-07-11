-- Transient read-aloud indicator: shows 🔊 with the engine (Kokoro / say) while
-- narration is active, switching to ⏸ when paused. State is published by the
-- speak()/narrate()/toggle_pause_speech() functions in config/keymaps.lua via
-- vim.g.tts_active / vim.g.tts_kind / vim.g.tts_paused, which also force a
-- lualine refresh so the indicator appears, flips, and clears promptly.
--
-- This also relocates the whole lualine bar from the bottom to the TOP of each
-- window: Neovim's real statusline is always bottom-anchored, so the only way to
-- get a top bar is the winbar. We render LazyVim's sections into the winbar,
-- empty the bottom statusline, and drop laststatus to 0 so no bottom line is
-- drawn. Note the winbar is per-window, so splits each get their own top bar.
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections = opts.sections or {}
    opts.sections.lualine_x = opts.sections.lualine_x or {}
    table.insert(opts.sections.lualine_x, 1, {
      function()
        local icon = vim.g.tts_paused and "⏸" or "🔊"
        return icon .. " " .. (vim.g.tts_kind or "reading")
      end,
      cond = function()
        return vim.g.tts_active == true
      end,
      color = { fg = "#fabd2f", gui = "bold" }, -- gruvbox bright yellow
    })

    -- Move the bar to the top. globalstatus must be off (a winbar is inherently
    -- per-window), and we mirror the statusline's disabled filetypes so the bar
    -- stays off the dashboard/starter screens.
    opts.options = opts.options or {}
    opts.options.globalstatus = false
    opts.options.disabled_filetypes = opts.options.disabled_filetypes or {}
    opts.options.disabled_filetypes.winbar = opts.options.disabled_filetypes.statusline
      or { "dashboard", "alpha", "ministarter", "snacks_dashboard" }

    -- Full bar → winbar; a minimal bar for inactive splits; bottom cleared.
    opts.winbar = opts.sections
    opts.inactive_winbar = {
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "location" },
    }
    opts.sections = {}
    opts.inactive_sections = {}
  end,
  config = function(_, opts)
    require("lualine").setup(opts)
    vim.opt.laststatus = 0 -- no bottom statusline; the bar now lives in the winbar
  end,
}
