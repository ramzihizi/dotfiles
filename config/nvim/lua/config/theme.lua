-- Colorscheme resolution for the theme switcher (config/bin/theme).
--
-- Two environments, two rules:
--   * wezterm + tmux ("work") stays on gruvbox, always. Detected by $TMUX or
--     $TERM_PROGRAM == "WezTerm", the same signal zshrc uses for the prompt.
--   * everything else (ghostty + herdr) follows the switcher's pointer file
--     ~/.config/active-theme, which holds "gruvbox" or "tokyo-night".
-- Defaults to gruvbox if the pointer is missing/unreadable, so a fresh machine
-- looks right before `theme` is ever run.

local M = {}

local function pointer_path()
  local base = vim.env.XDG_CONFIG_HOME
  if not base or base == "" then
    base = (vim.env.HOME or "~") .. "/.config"
  end
  return base .. "/active-theme"
end

-- Returns the nvim colorscheme name ("gruvbox" or "tokyonight").
function M.name()
  if vim.env.TMUX or vim.env.TERM_PROGRAM == "WezTerm" then
    return "gruvbox"
  end
  local f = io.open(pointer_path(), "r")
  if not f then
    return "gruvbox"
  end
  local value = vim.trim(f:read("*l") or "")
  f:close()
  if value == "tokyo-night" then
    return "tokyonight"
  end
  return "gruvbox"
end

-- Re-read the pointer and apply the colorscheme to the running instance. Wired
-- to the :ThemeReload command (see keymaps.lua) and invoked best-effort by the
-- `theme` script over each running nvim's socket.
function M.apply()
  pcall(vim.cmd.colorscheme, M.name())
end

return M
