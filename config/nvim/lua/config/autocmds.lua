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

-- No focus-based dimming of the editor: nvim keeps its normal colors when its
-- pane loses focus. (A DimOnUnfocus autocmd used to repaint Normal/NormalNC et
-- al. to a grey overlay on FocusLost; removed — whatever dimming happens should
-- come from the colorscheme or the terminal, not a hand-rolled highlight swap.)
