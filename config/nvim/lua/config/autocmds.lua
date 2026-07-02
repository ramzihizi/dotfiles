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
    -- Reload in every mode EXCEPT command-line ('c'), where checktime can
    -- interrupt the command being typed. (The old guard skipped normal/terminal
    -- mode instead, which defeated the point — CursorHold/BufEnter reloads
    -- fire in normal mode, so they never ran.)
    if vim.fn.mode() ~= "c" then
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

-- Autosave (the "send" half; AutoRead above is the "receive" half). Forgetting
-- to :w means Obsidian — which watches the vault and reloads external changes —
-- never sees the edit. Save on leaving the buffer or tabbing away from nvim,
-- NOT on every keystroke: writes stay infrequent and the window where the same
-- note is dirty in both nvim and Obsidian stays tiny. `:update` writes only
-- when the buffer is actually modified, so most BufLeave fires are a cheap
-- no-op. The guards skip anything that isn't a real, writable, on-disk file:
-- special buffers (nofile/terminal/help, the bidi scratch tab), unnamed
-- buffers, readonly, and non-modifiable buffers.
local save_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  group = save_group,
  callback = function(args)
    local buf = args.buf
    if
      vim.bo[buf].buftype ~= "" -- real file buffers only
      or not vim.bo[buf].modifiable
      or vim.bo[buf].readonly
      or not vim.bo[buf].modified
      or vim.api.nvim_buf_get_name(buf) == ""
    then
      return
    end
    -- Save this specific buffer even when the event fired for a different one.
    vim.api.nvim_buf_call(buf, function()
      pcall(vim.cmd, "silent! update")
    end)
  end,
  desc = "Autosave on focus-lost / buffer-leave",
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
-- The dim shade tracks the active colorscheme so it reads as a tone-correct
-- overlay, not a leftover. gruvbox → #303030 (the SAME grey tmux paints on
-- inactive shell panes via window-style in tmux.conf, so nvim and surrounding
-- panes dim to one tone in the wezterm+tmux env, over the "hard" bg #1d2021);
-- tokyonight → #292e42 (Tokyo Night's bg_highlight), a cool overlay over its
-- near-black bg. Keyed off vim.g.colors_name, so it follows a runtime
-- :ThemeReload (the theme switcher) without needing a restart.
local dim_group = vim.api.nvim_create_augroup("DimOnUnfocus", { clear = true })
local function dim_bg()
  local cs = vim.g.colors_name or ""
  if cs:match("^tokyonight") then
    return "#292e42"
  end
  return "#303030"
end
-- Background groups to override, with their original definitions cached on dim
-- and restored on un-dim. We deliberately do NOT re-source the colorscheme to
-- restore: a full re-source fires ColorScheme, which makes other plugins rebuild
-- their highlights every focus change (it was wiping the bufferline active-tab
-- highlight — see plugins/bufferline.lua) and is needlessly heavy. Caching the
-- exact prior groups restores the identical look without the churn.
local dim_targets = { "Normal", "NormalNC", "SignColumn", "LineNr", "EndOfBuffer", "FoldColumn" }
local saved_hl = nil

local function set_dim(on)
  if on then
    if saved_hl then return end -- already dimmed; don't cache the dimmed state
    saved_hl = {}
    for _, grp in ipairs(dim_targets) do
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = grp, link = false })
      if ok then
        saved_hl[grp] = hl
        local dimmed = vim.tbl_extend("force", {}, hl)
        dimmed.bg = dim_bg()
        pcall(vim.api.nvim_set_hl, 0, grp, dimmed)
      end
    end
  elseif saved_hl then
    for grp, hl in pairs(saved_hl) do
      pcall(vim.api.nvim_set_hl, 0, grp, hl)
    end
    saved_hl = nil
  end
end

-- If the colorscheme changes while dimmed, the cached groups are stale; drop
-- them so un-dim leaves the new theme's (undimmed) highlights in place.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = dim_group,
  callback = function()
    saved_hl = nil
  end,
  desc = "Invalidate cached dim highlights on colorscheme change",
})

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
