-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function define(text)
  text = vim.trim(text or "")
  if text == "" then
    vim.notify("No word selected", vim.log.levels.WARN)
    return
  end

  vim.ui.open("dict://" .. vim.uri_encode(text, "rfc3986"))
end

vim.keymap.set("n", "<leader>dw", function()
  define(vim.fn.expand("<cword>"))
end, { desc = "Define Word" })

vim.keymap.set("x", "<leader>dw", function()
  local saved_reg = vim.fn.getreg("v")
  local saved_type = vim.fn.getregtype("v")

  vim.cmd([[normal! "vy]])
  define(vim.fn.getreg("v"))

  vim.fn.setreg("v", saved_reg, saved_type)
end, { desc = "Define Selection" })
