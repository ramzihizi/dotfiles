-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })

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
local tts_paused = false

-- Reflect read-aloud state on the statusline (the lualine indicator in
-- plugins/lualine.lua reads vim.g.tts_active / vim.g.tts_kind) and force an
-- immediate redraw so it appears/clears without lualine's refresh-interval lag.
local function update_tts_status(kind)
  vim.g.tts_active = speech_job ~= nil
  vim.g.tts_kind = vim.g.tts_active and kind or nil
  if not vim.g.tts_active then
    tts_paused = false -- nothing playing can't be paused
  end
  vim.g.tts_paused = tts_paused
  pcall(function()
    require("lualine").refresh()
  end)
end

local function stop_speech()
  -- Resume first: a SIGSTOP'd (paused) process ignores SIGTERM until it
  -- continues, so un-pause before killing or a paused reader won't die.
  vim.fn.system({ "/usr/bin/pkill", "-CONT", "-x", "say" })

  if speech_job then
    vim.fn.jobstop(speech_job)
    speech_job = nil
  end

  vim.fn.system({ "/usr/bin/pkill", "-x", "say" })
  update_tts_status()
end

-- Pause / resume the `say` reader. `say` plays audio itself, so SIGSTOP/SIGCONT
-- on the process pauses and resumes the audible speech.
local function toggle_pause_speech()
  if not speech_job then
    vim.notify("Nothing is reading", vim.log.levels.WARN)
    return
  end
  local signal = tts_paused and "-CONT" or "-STOP"
  vim.fn.system({ "/usr/bin/pkill", signal, "-x", "say" })
  tts_paused = not tts_paused
  vim.g.tts_paused = tts_paused
  pcall(function()
    require("lualine").refresh()
  end)
  vim.notify(tts_paused and "⏸ Paused" or "▶ Resumed", vim.log.levels.INFO, { title = vim.g.tts_kind or "tts" })
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

vim.keymap.set("x", "<leader>dr", function()
  speak(visual_selection())
end, { desc = "Read Selection" })

vim.keymap.set("n", "<leader>ds", stop_speech, { desc = "Stop Reading" })
vim.keymap.set("n", "<leader>dP", toggle_pause_speech, { desc = "Pause/Resume Reading" })

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

-- Bidi (Arabic/RTL) reading view. Neither Neovim nor the terminal (Ghostty,
-- herdr) implements the Unicode bidirectional algorithm, so raw Arabic renders
-- shaped-but-reversed: nvim's 'arabicshape' joins the letters, but word order
-- stays logical (= visually backwards). GNU FriBidi runs the Bidi algorithm AND
-- Arabic joining, emitting terminal-ready visual order. We drop that into a
-- read-only scratch tab so the file on disk is never modified. --ltr fixes the
-- paragraph base direction so markdown markers (>, -, #, —) stay on the left
-- while each Arabic run is still reordered correctly. This is a VIEW, not an
-- editor — to type Arabic you'd want a bidi-aware plugin (e.g. bidi.nvim).
local function bidi_view()
  if vim.fn.executable("fribidi") == 0 then
    vim.notify("fribidi not found (brew install fribidi)", vim.log.levels.ERROR)
    return
  end

  local src = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local name = vim.fn.expand("%:t")
  local out =
    vim.fn.systemlist({ "fribidi", "--charset", "UTF-8", "--nopad", "--nobreak", "--ltr" }, table.concat(src, "\n"))
  if vim.v.shell_error ~= 0 then
    vim.notify("fribidi failed:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end

  -- Full-width scratch tab: long RTL lines aren't squeezed by a split. Plain
  -- (no filetype) on purpose — a faithful, verbatim view with no markdown
  -- plugin re-processing the already-reordered presentation forms. `q` closes.
  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, buf, "bidi://" .. (name ~= "" and name or "buffer"))
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true, desc = "Close bidi view" })
end

vim.api.nvim_create_user_command("BidiView", bidi_view, { desc = "Arabic/RTL reading view (FriBidi)" })
vim.keymap.set("n", "<leader>mb", bidi_view, { desc = "Bidi (Arabic) view" })

-- Open today's daily note in the rmh-wiki vault. Heavy journaling lives in the
-- Obsidian app, but this is a quick capture path from Neovim. Mirrors the old
-- obsidian.nvim daily-notes layout: raw/journal/personal/YYYY/YYYY-MM-DD.md.
local function daily_note()
  local dir = vim.fn.expand("~/bsdn/rmh-wiki/raw/journal/personal/" .. os.date("%Y"))
  vim.fn.mkdir(dir, "p")
  vim.cmd.edit(dir .. "/" .. os.date("%Y-%m-%d") .. ".md")
end

vim.keymap.set("n", "<leader>od", daily_note, { desc = "Daily Note (today)" })

-- Re-apply the active colorscheme from ~/.config/active-theme without
-- restarting. The `theme` switcher (config/bin/theme) sends this to every
-- running nvim after a switch; also runnable by hand as :ThemeReload.
vim.api.nvim_create_user_command("ThemeReload", function()
  require("config.theme").apply()
end, { desc = "Re-apply theme from ~/.config/active-theme" })
