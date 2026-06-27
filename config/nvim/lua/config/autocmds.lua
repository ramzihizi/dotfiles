-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local group = vim.api.nvim_create_augroup("AutoRead", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = group,
  callback = function()
    local mode = vim.api.nvim_get_mode().mode
    if not mode:match("^[nt]") then
      pcall(vim.cmd.checktime)
    end
  end,
  desc = "Auto-reload changed files on focus/move/idle",
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group,
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN, { title = "nvim" })
  end,
  desc = "Notify after auto-reload",
})

-- Disable spell (and optionally wrap) for prose-like filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.spell = false
    -- vim.opt_local.wrap = false -- uncomment if you also want wrap off
  end,
  desc = "Disable spell for markdown/gitcommit/text",
})

-- Dim the editor when its pane loses focus, so the active pane is obvious.
-- On FocusLost we shift the background groups to a darker overlay and restore
-- on FocusGained. The active bg is near-black, so the unfocused shade reads as
-- a lighter overlay rather than blending in. Requires focus events to reach
-- nvim (`set -g focus-events on` in tmux.conf, already set).
--
-- The dim shade matches the active environment's colorscheme, using the same
-- $TMUX / $TERM_PROGRAM detection as plugins/colorscheme.lua:
--   wezterm + tmux  -> gruvbox: neutral #303030, the SAME shade tmux paints on
--                      inactive shell panes (window-style in tmux.conf), so
--                      nvim and the surrounding panes dim to one tone.
--   ghostty + herdr -> tokyonight (transparent, "night"): blue-tinted #292e42
--                      (tokyonight's bg_highlight) so the dim harmonizes with
--                      the cool palette and reads as a lighter overlay over
--                      ghostty's #1a1b26 background instead of a warm gray.
local dim_group = vim.api.nvim_create_augroup("DimOnUnfocus", { clear = true })
local in_wezterm = vim.env.TMUX ~= nil or vim.env.TERM_PROGRAM == "WezTerm"
local DIM_BG = in_wezterm and "#303030" or "#292e42"
-- Background groups to override. Restored by re-applying the colorscheme, which
-- is cheap and robust against gruvbox variants / future theme swaps.
local dim_targets = { "Normal", "NormalNC", "SignColumn", "LineNr", "EndOfBuffer", "FoldColumn" }

local function set_dim(on)
  if on then
    for _, grp in ipairs(dim_targets) do
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = grp, link = false })
      if ok then
        hl.bg = DIM_BG
        pcall(vim.api.nvim_set_hl, 0, grp, hl)
      end
    end
  else
    -- Re-source the active colorscheme to restore exact original highlights.
    local scheme = vim.g.colors_name
    if scheme then
      pcall(vim.cmd.colorscheme, scheme)
    end
  end
end

vim.api.nvim_create_autocmd("FocusLost", {
  group = dim_group,
  callback = function()
    set_dim(true)
  end,
  desc = "Dim editor background when tmux pane is inactive",
})

vim.api.nvim_create_autocmd("FocusGained", {
  group = dim_group,
  callback = function()
    set_dim(false)
  end,
  desc = "Restore editor background when tmux pane regains focus",
})
