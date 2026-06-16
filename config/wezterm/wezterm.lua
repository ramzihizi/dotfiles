-- WezTerm config — ports the kitty + tmux setup to a single tool.
-- WezTerm is BOTH a GPU terminal emulator (replaces kitty) AND a
-- multiplexer (replaces tmux: panes, tabs, workspaces). Lua config,
-- auto-reloads on save — no `source-file` reload needed.
--
-- Linked by bootstrap.sh to ~/.config/wezterm/

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ============ Appearance (ported from kitty) ============

-- Theme: Tokyo Night (built-in scheme; matches kitty + tmux)
config.color_scheme = "Tokyo Night"

-- Font: Dank Mono @ 13. Only Regular + (cursive) Italic faces are installed,
-- so bold is synthesized by wezterm. Operator Mono kept as fallback.
-- Italic auto-resolves to "Dank Mono Italic" — no font_rules needed.
config.font = wezterm.font_with_fallback({
	{ family = "Dank Mono", weight = "Regular" },
	"Operator Mono",
})
config.font_size = 13.0

-- Cursor: teal #1abc9c, non-blinking (kitty: cursor #1abc9c / blink_interval 0)
config.colors = {
	cursor_bg = "#1abc9c",
	cursor_border = "#1abc9c",
	cursor_fg = "#1a1b26", -- text under cursor = background color
}
config.default_cursor_style = "SteadyBlock"
config.cursor_blink_rate = 0

-- Window: 0.9 opacity, no title bar (keep resize), small padding.
config.window_background_opacity = 0.9
-- No blur: keep what's behind wezterm sharp/readable, not frosted.
config.macos_window_background_blur = 0
config.window_decorations = "RESIZE"
config.window_padding = { left = 6, right = 6, top = 6, bottom = 0 }

-- Dim inactive panes harder than the default (0.9 / 0.8) so the active
-- pane stands out. Lower brightness = darker inactive; tweak to taste.
config.inactive_pane_hsb = {
	saturation = 0.7,
	brightness = 0.5,
}

-- Tab bar at bottom (tmux-like). Hidden when only one tab.
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true

-- macOS: Option acts as Alt (kitty: macos_option_as_alt yes)
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- ============ Multiplexer keys (ported from tmux) ============
-- Leader = Ctrl-a. NOT Ctrl-b: herdr (the AI-agent multiplexer that runs
-- inside wezterm) uses Ctrl-b like tmux, so wezterm must stay clear of it.
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- Send a literal Ctrl-a to the shell (leader a), like tmux `send-prefix`.
	-- Recovers the shell's beginning-of-line shortcut that the leader shadows.
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- Splits: | side-by-side, - stacked. Inherit cwd automatically.
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Pane select with leader+hjkl (tmux `prefix h/j/k/l`)
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- Zoom a pane (tmux `prefix m` / `prefix z`)
	{ key = "m", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

	-- Windows == tmux windows == wezterm TABS
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = ",", mods = "LEADER", action = act.PromptInputLine({
		description = "Rename tab",
		action = wezterm.action_callback(function(window, _, line)
			if line then
				window:active_tab():set_title(line)
			end
		end),
	}) },

	-- Sessions == wezterm WORKSPACES. leader+s lists, leader+$ renames.
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	-- Create + switch to a named workspace (tmux `new -s name`)
	{ key = "w", mods = "LEADER", action = act.PromptInputLine({
		description = "New workspace name",
		action = wezterm.action_callback(function(window, pane, line)
			if line and #line > 0 then
				window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
			end
		end),
	}) },
	{ key = "$", mods = "LEADER|SHIFT", action = act.PromptInputLine({
		description = "Rename workspace",
		action = wezterm.action_callback(function(_, _, line)
			if line then
				wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
			end
		end),
	}) },
	{ key = "d", mods = "LEADER", action = act.DetachDomain("CurrentPaneDomain") },

	-- Copy mode (tmux `prefix [`). v/y work inside it by default.
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },

	-- Resize mode: leader+r, then hjkl (repeatable). Esc/q to exit.
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize", one_shot = false }) },

	-- Opacity control (kitty: ctrl+shift+a > m/l/1/d)
	{ key = "a", mods = "CTRL|SHIFT", action = act.ActivateKeyTable({ name = "opacity", one_shot = false }) },

	-- Speak selection via macOS `say` (kitty + tmux: this was cmd+shift+r / R)
	{ key = "r", mods = "CMD|SHIFT", action = wezterm.action_callback(function(window, pane)
		local text = window:get_selection_text_for_pane(pane)
		if text and #text > 0 then
			wezterm.background_child_process({ "/usr/bin/say", text })
		end
	end) },
}

-- Switch to tab N with leader+1..9 (tmux `prefix 0-9`)
for i = 1, 9 do
	table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) })
end

-- ============ Key tables ============
local function adjust_opacity(delta)
	return wezterm.action_callback(function(window)
		local o = window:get_config_overrides() or {}
		o.window_background_opacity = math.max(0.1, math.min(1.0, (o.window_background_opacity or 0.9) + delta))
		window:set_config_overrides(o)
	end)
end

config.key_tables = {
	-- tmux `prefix -r H/J/K/L` resize, 5 units. Esc/q exits.
	resize = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "q", action = "PopKeyTable" },
	},
	-- kitty opacity bindings
	opacity = {
		{ key = "m", action = adjust_opacity(0.1) },
		{ key = "l", action = adjust_opacity(-0.1) },
		{ key = "1", action = wezterm.action_callback(function(w)
			local o = w:get_config_overrides() or {}
			o.window_background_opacity = 1.0
			w:set_config_overrides(o)
		end) },
		{ key = "d", action = wezterm.action_callback(function(w)
			w:set_config_overrides({})
		end) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "q", action = "PopKeyTable" },
	},
}

-- ============ Seamless Ctrl-hjkl nav (replaces vim-tmux-navigator) ============
-- smart-splits is the modern cross-tool replacement for vim-tmux-navigator.
-- It gives Ctrl-h/j/k/l navigation that hands off to Neovim splits when the
-- focused pane runs nvim. Requires the matching `smart-splits.nvim` plugin in
-- Neovim (see cheatsheet). pcall so the config still loads if it can't fetch.
local ok, smart_splits = pcall(function()
	return wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
end)
if ok and smart_splits then
	smart_splits.apply_to_config(config, {
		direction_keys = { "h", "j", "k", "l" },
		modifiers = { move = "CTRL", resize = "META" },
	})
else
	-- Fallback: plain Ctrl-hjkl pane navigation (no nvim hand-off).
	for key, dir in pairs({ h = "Left", j = "Down", k = "Up", l = "Right" }) do
		table.insert(config.keys, { key = key, mods = "CTRL", action = act.ActivatePaneDirection(dir) })
	end
end

return config
