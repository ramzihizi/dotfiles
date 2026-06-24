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
local narrate_job

local function stop_speech()
  if speech_job then
    vim.fn.jobstop(speech_job)
    speech_job = nil
  end

  if narrate_job then
    vim.fn.jobstop(narrate_job)
    narrate_job = nil
  end

  vim.fn.system({ "/usr/bin/pkill", "-x", "say" })
  vim.fn.system({ "/usr/bin/pkill", "-x", "afplay" })
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

local function narrate(text)
  text = vim.trim(text or "")
  if text == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  stop_speech()

  local bin = vim.fn.expand("~/.local/bin/narrate")
  if vim.fn.executable(bin) == 0 then
    vim.notify("narrate not found at " .. bin, vim.log.levels.ERROR)
    return
  end

  narrate_job = vim.fn.jobstart({ bin }, {
    on_exit = function()
      narrate_job = nil
    end,
  })

  if narrate_job <= 0 then
    narrate_job = nil
    vim.notify("Could not start narrate", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(narrate_job, text)
  vim.fn.chanclose(narrate_job, "stdin")
end

vim.keymap.set("x", "<leader>dr", function()
  speak(visual_selection())
end, { desc = "Read Selection" })

vim.keymap.set("x", "<leader>dR", function()
  narrate(visual_selection())
end, { desc = "Read Selection (Kokoro)" })

vim.keymap.set("n", "<leader>ds", stop_speech, { desc = "Stop Reading" })
