-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function visual_selection()
  local mode = vim.fn.mode()
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    mode = vim.fn.visualmode()
    start_pos = vim.fn.getpos("'<")
    end_pos = vim.fn.getpos("'>")
  end

  local is_visual_mode = mode == "v" or mode == "V" or mode == "\22"
  local opts = is_visual_mode and { type = mode } or vim.empty_dict()
  local lines = vim.fn.getregion(start_pos, end_pos, opts)
  return table.concat(lines, "\n")
end

local function define(text)
  text = vim.trim(text or "")
  if text == "" then
    vim.notify("No word selected", vim.log.levels.WARN)
    return
  end

  vim.ui.open("dict://" .. vim.uri_encode(text, "rfc3986"))
end

local speech_job

local function stop_speech()
  if speech_job then
    vim.fn.jobstop(speech_job)
    speech_job = nil
  end

  vim.fn.system({ "/usr/bin/pkill", "-x", "say" })
end

local function speak(text)
  text = vim.trim(text or "")
  if text == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  stop_speech()
  speech_job = vim.fn.jobstart({ "/usr/bin/say" }, {
    on_exit = function()
      speech_job = nil
    end,
  })

  if speech_job <= 0 then
    speech_job = nil
    vim.notify("Could not start /usr/bin/say", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(speech_job, text)
  vim.fn.chanclose(speech_job, "stdin")
end

vim.keymap.set("n", "<leader>dw", function()
  define(vim.fn.expand("<cword>"))
end, { desc = "Define Word" })

vim.keymap.set("x", "<leader>dw", function()
  define(visual_selection())
end, { desc = "Define Selection" })

vim.keymap.set("x", "<leader>dr", function()
  speak(visual_selection())
end, { desc = "Read Selection" })

vim.keymap.set("n", "<leader>ds", stop_speech, { desc = "Stop Reading" })

local function mdview()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No file in buffer", vim.log.levels.WARN)
    return
  end

  local bin = vim.fn.expand("~/.local/bin/mdview")
  if vim.fn.executable(bin) == 0 then
    vim.notify("mdview not found at " .. bin, vim.log.levels.ERROR)
    return
  end

  if vim.bo.modified then
    vim.cmd("write")
  end

  vim.fn.jobstart({ bin, file })
end

vim.api.nvim_create_user_command("MdView", mdview, { desc = "Render markdown + mermaid in browser" })
vim.keymap.set("n", "<leader>mv", mdview, { desc = "Markdown+mermaid preview" })
