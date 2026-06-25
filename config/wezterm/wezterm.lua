-- WezTerm config — mirrors the kitty setup for a wezterm + tmux flow.
-- WezTerm is JUST the GPU terminal emulator here (a kitty replacement);
-- tmux does all the multiplexing (panes, windows, sessions) and owns the
-- Ctrl-b prefix, so wezterm stays out of its way and binds no mux keys.
-- Lua config, auto-reloads on save — no reload keybinding needed.
--
-- Linked by bootstrap.sh to ~/.config/wezterm/

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ============ Appearance (ported from kitty) ============

-- Theme: Gruvbox Dark (built-in scheme; matches tmux + nvim in this env).
-- Deliberately warm/amber here so wezterm+tmux is visually unmistakable from
-- the ghostty+herdr environment, which stays Tokyo Night (cool/blue).
config.color_scheme = "Gruvbox Dark"

-- Font: SF Mono (Apple's monospace, installed at /Library/Fonts/SF-Mono-*.otf).
-- Ships real Regular/Medium/Bold + matching italics, so wezterm synthesizes
-- nothing. SF Mono has no icon glyphs, so the Nerd Font fallbacks stay: BlexMono
-- Nerd Font Mono covers tmux status + prompt icons (kitty auto-falls-back to the
-- same; wezterm must name it explicitly or tokyo-night-tmux's Nerd Font v3 glyphs
-- render as tofu — the "Mono" variant forces icons to single-cell width).
config.font = wezterm.font_with_fallback({
	{ family = "SF Mono", weight = "Regular" },
	"BlexMono Nerd Font Mono",
	-- tokyo-night-tmux draws window numbers with U+1FBF0+ "segmented digits"
	-- (its default `digital` id style), which Blex lacks — so they vanished in
	-- wezterm while kitty fell back to a font that has them. Monaspace Nerd Font
	-- covers that block; this makes the window-index numbers show like in kitty.
	"MonaspiceNe Nerd Font Mono",
})
config.font_size = 13.0

-- Cursor + selection: gruvbox yellow cursor, warm-grey selection (non-blinking).
-- Yellow #b57614 reads as gruvbox, not the old teal; selection uses bg2 #504945
-- so highlighted text stays on-theme instead of teal/blue.
config.colors = {
	cursor_bg = "#b57614",
	cursor_border = "#b57614",
	cursor_fg = "#282828", -- text under cursor = background color (Gruvbox Dark bg)
	selection_bg = "#504945", -- gruvbox bg2 (warm grey)
	selection_fg = "#ebdbb2", -- gruvbox fg
	-- Warm down the scheme's bright yellow: Gruvbox Dark's brights[4] is #fabd2f,
	-- which reads as harsh in `ls`/terminal output. Drop it to the faded/ochre
	-- yellow #b57614 (matches nvim, starship, tmux). All other brights are Gruvbox Dark's
	-- defaults, restated here because wezterm needs the full 8-colour array.
	brights = {
		"#928374", -- black
		"#fb4934", -- red
		"#b8bb26", -- green
		"#b57614", -- yellow (was #fabd2f)
		"#83a598", -- blue
		"#d3869b", -- magenta
		"#8ec07c", -- cyan
		"#ebdbb2", -- white
	},
}
config.default_cursor_style = "SteadyBlock"
config.cursor_blink_rate = 0

-- Window: 0.9 opacity, no title bar (keep resize), small padding.
config.window_background_opacity = 0.9
-- No blur: keep what's behind wezterm sharp/readable, not frosted.
config.macos_window_background_blur = 0
-- Keep the macOS window shadow off even at full opacity; WezTerm already
-- disables it automatically below 1.0 opacity.
config.window_decorations = "RESIZE | MACOS_FORCE_DISABLE_SHADOW"
config.window_padding = { left = 6, right = 6, top = 6, bottom = 0 }

-- Tab bar mirrors kitty's: a plain bar at the bottom, hidden while a single
-- tab is open. Under tmux that's the normal case, so it stays out of sight;
-- tmux's own status line is the one you actually read.
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true

-- macOS: Option acts as Alt (kitty: macos_option_as_alt yes)
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Honor the kitty keyboard protocol, like kitty does natively. tmux.conf runs
-- `extended-keys on` / `csi-u` (added for pi) to receive disambiguated modified
-- keys; kitty supports that out of the box, wezterm only when this is set. This
-- matches kitty's key handling.
-- NOTE: Ctrl-h/j/k/l pane navigation does NOT depend on this. That hinges on
-- Karabiner excluding wezterm from its global ctrl+hjkl→arrow-keys remap — see
-- config/karabiner/karabiner.json. Without that exclusion the keys arrive as
-- literal arrow keys and never reach tmux as C-h/j/k/l at all.
config.enable_kitty_keyboard = true

-- ============ Keys (only kitty's two; tmux gets everything else) ============
-- No leader, no pane/tab/workspace/copy-mode bindings — tmux owns all of that
-- via its Ctrl-b prefix. Ctrl-h/j/k/l are deliberately left unbound so they
-- pass through to tmux + vim-tmux-navigator; wezterm's only Ctrl+letter
-- defaults here are Ctrl+SHIFT (clear scrollback / debug overlay), so plain
-- Ctrl-hjkl don't collide.

config.keys = {
	-- Opacity control (kitty: ctrl+shift+a > m/l/1/d)
	{ key = "a", mods = "CTRL|SHIFT", action = act.ActivateKeyTable({ name = "opacity", one_shot = false }) },

	-- Speak selection via macOS `say` (kitty: cmd+shift+r)
	{
		key = "r",
		mods = "CMD|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			local text = window:get_selection_text_for_pane(pane)
			if text and #text > 0 then
				wezterm.background_child_process({ "/usr/bin/say", text })
			end
		end),
	},
}

-- ============ Key tables ============
local function adjust_opacity(delta)
	return wezterm.action_callback(function(window)
		local o = window:get_config_overrides() or {}
		o.window_background_opacity = math.max(0.1, math.min(1.0, (o.window_background_opacity or 0.9) + delta))
		window:set_config_overrides(o)
	end)
end

config.key_tables = {
	-- kitty opacity bindings
	opacity = {
		{ key = "m", action = adjust_opacity(0.1) },
		{ key = "l", action = adjust_opacity(-0.1) },
		{
			key = "1",
			action = wezterm.action_callback(function(w)
				local o = w:get_config_overrides() or {}
				o.window_background_opacity = 1.0
				w:set_config_overrides(o)
			end),
		},
		{ key = "d", action = wezterm.action_callback(function(w)
			w:set_config_overrides({})
		end) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "q", action = "PopKeyTable" },
	},
}

return config
