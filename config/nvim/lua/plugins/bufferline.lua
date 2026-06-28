-- Make the active buffer stand out in the bufferline.
--
-- Both colorschemes run transparent (tokyonight + gruvbox), which zeroes every
-- bufferline background — so the selected tab has no fill and every buffer reads
-- the same against the terminal bg. We give the *selected* tab a solid raised
-- background + bold bright text and dim the inactive tabs, so the current buffer
-- is obvious.
--
-- Colors go through bufferline's OWN `highlights` config: bufferline re-applies
-- its groups on every ColorScheme via `config.update_highlights()`, which
-- re-merges this table over freshly-derived defaults — so these survive theme
-- reloads (a raw nvim_set_hl override would be wiped). Pairs with the dim in
-- config/autocmds.lua, which no longer re-sources the colorscheme on focus.
-- Palette is chosen from the active colorscheme: herdr (tokyonight) / wezterm
-- (gruvbox).
return {
  "akinsho/bufferline.nvim",
  opts = function(_, opts)
    -- raised bg · bright fg · dim fg · accent, per theme.
    local palettes = {
      tokyonight = { sel = "#292e42", fg = "#c0caf5", dim = "#565f89", accent = "#7aa2f7" },
      gruvbox = { sel = "#3c3836", fg = "#ebdbb2", dim = "#928374", accent = "#b57614" },
      -- Solarized: base02 raised bg · base1 bright fg · base01 dim · blue accent.
      solarized = { sel = "#073642", fg = "#93a1a1", dim = "#586e75", accent = "#268bd2" },
    }
    -- colors_name is "tokyonight-night" / "gruvbox" / "solarized" / etc — match
    -- by substring.
    local name = vim.g.colors_name or ""
    local p = name:find("solarized") and palettes.solarized
      or name:find("gruvbox") and palettes.gruvbox
      or palettes.tokyonight

    opts.options = opts.options or {}
    -- A visible bar on the active buffer, independent of background fill.
    opts.options.indicator = { style = "icon", icon = "▎" }

    -- Per-attribute overrides, merged over bufferline's computed defaults: every
    -- "selected" segment shares the raised bg so the active tab reads as one
    -- solid block (each segment keeps its own fg), and inactive tabs are dimmed.
    local sel = { bg = p.sel, bold = true }
    opts.highlights = vim.tbl_deep_extend("force", opts.highlights or {}, {
      background = { fg = p.dim },
      buffer_visible = { fg = p.fg },
      buffer_selected = { fg = p.fg, bg = p.sel, bold = true, italic = false },
      numbers_selected = sel,
      modified_selected = { bg = p.sel },
      duplicate_selected = { bg = p.sel, italic = true },
      close_button_selected = { bg = p.sel },
      indicator_selected = { fg = p.accent, bg = p.sel },
      separator_selected = { fg = p.sel, bg = p.sel },
      pick_selected = sel,
      error_selected = sel,
      warning_selected = sel,
      info_selected = sel,
      hint_selected = sel,
      error_diagnostic_selected = { bg = p.sel },
      warning_diagnostic_selected = { bg = p.sel },
      info_diagnostic_selected = { bg = p.sel },
      hint_diagnostic_selected = { bg = p.sel },
    })
    return opts
  end,
}
