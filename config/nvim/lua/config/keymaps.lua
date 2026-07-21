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

vim.keymap.set("n", "<leader>dw", function()
  define(vim.fn.expand("<cword>"))
end, { desc = "Define Word" })

vim.keymap.set("x", "<leader>dw", function()
  define(visual_selection())
end, { desc = "Define Selection" })

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
