-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable spell checking globally (LazyVim respects this)
vim.opt.spell = false

-- Enable external change detection and faster CursorHold
vim.o.autoread = true
vim.o.updatetime = 500

-- TEST: This comment verifies live config edits.
-- You can remove it after confirming Neovim reload behavior.
