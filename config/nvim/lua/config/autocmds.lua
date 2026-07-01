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
-- On FocusLost we lift the background groups to a subtle overlay and drop back
-- to transparent on FocusGained. Requires focus events to reach nvim — both
-- tmux (`set -g focus-events on`) and herdr forward them (herdr speaks DECSET
-- 1004 focus reporting).
--
-- The overlay is #242424: just above the darkened gruvbox base (#161819), so it
-- reads as "inactive" without the harsh jump the old #303030 made against the
-- darker background. Kept in sync with tmux.conf's window-style so nvim and
-- shell panes dim to one tone.
local dim_group = vim.api.nvim_create_augroup("DimOnUnfocus", { clear = true })
local DIM_BG = "#242424"
-- All our colorschemes run transparent (transparent_mode / transparent), so the
-- *undimmed* background for these groups is "NONE" — the terminal shows through.
-- We rely on that instead of caching-and-restoring prior highlights: the old
-- cache got poisoned when a ColorScheme event fired mid-dim (it invalidated the
-- cache, then a later FocusLost re-cached the ALREADY dimmed #303030 as the
-- "original" and baked it in — the stuck-gray bug). A deterministic toggle
-- between DIM_BG and NONE can't get stuck.
local dim_targets = { "Normal", "NormalNC", "SignColumn", "LineNr", "EndOfBuffer", "FoldColumn" }
local is_dimmed = false

local function apply_dim()
  for _, grp in ipairs(dim_targets) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = grp, link = false })
    if ok then
      hl.bg = is_dimmed and DIM_BG or "NONE"
      pcall(vim.api.nvim_set_hl, 0, grp, hl)
    end
  end
end

-- A ColorScheme reload repaints these groups from scratch. If we're currently
-- unfocused, re-apply the overlay once the new highlights land (scheduled to run
-- after the colorscheme finishes). When focused there's nothing to do — the
-- fresh theme is already the correct undimmed look.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = dim_group,
  callback = function()
    if is_dimmed then vim.schedule(apply_dim) end
  end,
  desc = "Re-apply dim overlay after a colorscheme reload if still unfocused",
})

vim.api.nvim_create_autocmd("FocusLost", {
  group = dim_group,
  callback = function()
    is_dimmed = true
    apply_dim()
  end,
  desc = "Dim editor background when the pane is inactive",
})

vim.api.nvim_create_autocmd("FocusGained", {
  group = dim_group,
  callback = function()
    is_dimmed = false
    apply_dim()
  end,
  desc = "Restore editor background when the pane regains focus",
})
