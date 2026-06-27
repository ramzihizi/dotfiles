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

-- Reflect read-aloud state on the statusline (the lualine indicator in
-- plugins/lualine.lua reads vim.g.tts_active / vim.g.tts_kind) and force an
-- immediate redraw so it appears/clears without lualine's refresh-interval lag.
local function update_tts_status(kind)
  vim.g.tts_active = speech_job ~= nil or narrate_job ~= nil
  vim.g.tts_kind = vim.g.tts_active and kind or nil
  pcall(function()
    require("lualine").refresh()
  end)
end

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
  update_tts_status()
end

-- Strip Markdown so TTS reads words, not punctuation. Removes emphasis/code
-- markers (* ` ~~), unwraps [label](url) -> label, and drops line-start heading
-- (#), blockquote (>) and list-bullet (-, +) markers. Leaves prose, hyphenated
-- words and snake_case untouched.
local function clean_for_speech(text)
  text = text or ""
  text = text:gsub("!?%[([^%]]*)%]%([^)]*%)", "%1") -- images/links -> label
  text = text:gsub("`+", "") -- inline/fenced code backticks
  text = text:gsub("%*+", "") -- bold/italic asterisks
  text = text:gsub("~~", "") -- strikethrough
  text = text:gsub("/+", " ") -- slashes -> space ("and/or" reads "and or", not "slash")
  text = text:gsub("^%s*#+%s*", "") -- heading marker, first line
  text = text:gsub("\n%s*#+%s*", "\n") -- heading markers, later lines
  text = text:gsub("^%s*>+%s*", "") -- blockquote, first line
  text = text:gsub("\n%s*>+%s*", "\n") -- blockquote, later lines
  text = text:gsub("^%s*[-+]%s+", "") -- list bullet, first line
  text = text:gsub("\n%s*[-+]%s+", "\n") -- list bullets, later lines
  return text
end

local function speak(text)
  text = vim.trim(clean_for_speech(text))
  if text == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  stop_speech()
  speech_job = vim.fn.jobstart({ "/usr/bin/say" }, {
    on_exit = function()
      speech_job = nil
      update_tts_status()
    end,
  })

  if speech_job <= 0 then
    speech_job = nil
    vim.notify("Could not start /usr/bin/say", vim.log.levels.ERROR)
    return
  end

  update_tts_status("say")
  vim.notify("🔊 Reading…", vim.log.levels.INFO, { title = "say" })
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
  text = vim.trim(clean_for_speech(text))
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

  local stderr = {}
  narrate_job = vim.fn.jobstart({ bin }, {
    stderr_buffered = true,
    on_stderr = function(_, data)
      for _, line in ipairs(data or {}) do
        if line ~= "" then
          stderr[#stderr + 1] = line
        end
      end
    end,
    on_exit = function(_, code)
      narrate_job = nil
      update_tts_status()
      if code ~= 0 then
        local msg = vim.trim(table.concat(stderr, "\n"))
        vim.notify(
          "narrate failed" .. (msg ~= "" and ":\n" .. msg or " (exit " .. code .. ")"),
          vim.log.levels.ERROR,
          { title = "narrate" }
        )
      end
    end,
  })

  if narrate_job <= 0 then
    narrate_job = nil
    vim.notify("Could not start narrate", vim.log.levels.ERROR)
    return
  end

  update_tts_status("Kokoro")
  vim.notify("🔊 Narrating…", vim.log.levels.INFO, { title = "narrate" })
  vim.fn.chansend(narrate_job, text)
  vim.fn.chanclose(narrate_job, "stdin")
end

vim.keymap.set("x", "<leader>dr", function()
  speak(visual_selection())
end, { desc = "Read Selection" })

-- Kokoro read-aloud: only bind when the narrate CLI is actually installed
-- (bootstrap symlinks it only on machines with Murmur's runtime). Keeps the
-- mapping absent elsewhere instead of binding a key that just errors.
if vim.fn.executable(vim.fn.expand("~/.local/bin/narrate")) == 1 then
  vim.keymap.set("x", "<leader>dR", function()
    narrate(visual_selection())
  end, { desc = "Read Selection (Kokoro)" })
end

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

-- Open today's daily note in the rmh-wiki vault. Heavy journaling lives in the
-- Obsidian app, but this is a quick capture path from Neovim. Mirrors the old
-- obsidian.nvim daily-notes layout: raw/journal/personal/YYYY/YYYY-MM-DD.md.
local function daily_note()
  local dir = vim.fn.expand("~/bsdn/rmh-wiki/raw/journal/personal/" .. os.date("%Y"))
  vim.fn.mkdir(dir, "p")
  vim.cmd.edit(dir .. "/" .. os.date("%Y-%m-%d") .. ".md")
end

vim.keymap.set("n", "<leader>od", daily_note, { desc = "Daily Note (today)" })

-- Jump between harper's grammar/style suggestions the way ]e/]w jump errors and
-- warnings. Harper is scoped to markdown/gitcommit and emitted at HINT severity,
-- so ]g/[g cycle its prose recommendations (and float the message on landing).
local function grammar_jump(count)
  return function()
    vim.diagnostic.jump({ count = count, severity = vim.diagnostic.severity.HINT, float = true })
  end
end

vim.keymap.set("n", "]g", grammar_jump(1), { desc = "Next Grammar Hint (harper)" })
vim.keymap.set("n", "[g", grammar_jump(-1), { desc = "Prev Grammar Hint (harper)" })
