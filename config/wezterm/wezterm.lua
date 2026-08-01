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

-- Theme: Rosé Pine Moon (bg #232136) — cool purple, so wezterm+tmux stays
-- visually distinct from the ghostty+herdr environment (Gruvbox Dark Hard,
-- bg #1d2021). Some overrides in `config.colors` below are still gruvbox
-- leftovers from the previous scheme (selection, brights); they're warm
-- against Moon's cool base but deliberate — see the note there.
-- Scheme names must match wezterm's built-in list EXACTLY: the old value here
-- was once a bare "Gruvbox Dark", which is not a real name, so wezterm logged
-- "scheme not found", silently fell back to its default, and the manual color
-- overrides below hid the regression. Check the name if colors look off.
-- config.color_scheme = "Gruvbox Dark (Gogh)"
config.color_scheme = "rose-pine-moon"

-- Font: BlexMono Nerd Font Mono (primary) — same primary as ghostty
-- (config/ghostty/config:1), also at size 13, so both terminals read identically.
-- Blex carries the tmux-status / prompt icons on its own; the "Mono" variant
-- forces icons to single-cell width. Monaspice covers tokyo-night-tmux's
-- U+1FBF0+ segmented digits, which Blex lacks. Comic Code stays last as an
-- opt-in: it has no icon glyphs, so it can never be primary without tofu.
config.font = wezterm.font_with_fallback({
	"BlexMono Nerd Font Mono",
	"MonaspiceNe Nerd Font Mono",
	"Comic Code Ligatures",
})

-- Previous font: SF Mono (Apple's monospace, installed at /Library/Fonts/SF-Mono-*.otf).
-- Ships real Regular/Medium/Bold + matching italics, so wezterm synthesizes
-- nothing. SF Mono has no icon glyphs, so the Nerd Font fallbacks stay: BlexMono
-- Nerd Font Mono covers tmux status + prompt icons (kitty auto-falls-back to the
-- same; wezterm must name it explicitly or tokyo-night-tmux's Nerd Font v3 glyphs
-- render as tofu — the "Mono" variant forces icons to single-cell width).
-- config.font = wezterm.font_with_fallback({
-- 	{ family = "SF Mono", weight = "Regular" },
-- 	"BlexMono Nerd Font Mono",
-- 	-- tokyo-night-tmux draws window numbers with U+1FBF0+ "segmented digits"
-- 	-- (its default `digital` id style), which Blex lacks — so they vanished in
-- 	-- wezterm while kitty fell back to a font that has them. Monaspace Nerd Font
-- 	-- covers that block; this makes the window-index numbers show like in kitty.
-- 	"MonaspiceNe Nerd Font Mono",
-- })
config.font_size = 13

-- Cursor + selection: hacker-green cursor, warm-grey selection (non-blinking).
-- #00FF00 deliberately matches herdr's accent (config/herdr/config.toml), so the
-- cursor and the active-tab/focused-pane highlight read as one colour across the
-- whole environment. It is NOT from the Rosé Pine palette — that is the point: it
-- sits outside the scheme so it never blends into it. (The previous gruvbox ochre
-- #b57614 vanished against Moon's dark purple base; Moon's own gold #f6c177 works
-- too if the green ever gets tiring.)
-- `colors` wins over `color_scheme` per-key, so these override Moon's defaults.
config.colors = {
	cursor_bg = "#00FF00",
	cursor_border = "#00FF00",
	cursor_fg = "#232136", -- text under cursor = background color (Rosé Pine Moon base)
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

-- Window: 0.8 opacity, no title bar (keep resize), small padding.
config.window_background_opacity = 0.8
-- Frosted glass: heavy blur so what's behind the window is present but unreadable.
-- Deliberate trade-off — blur + sub-1.0 opacity mute painted background cells, so
-- herdr's #00FF00 accent (active tab, focused pane border) reads softer here than
-- in ghostty. WezTerm has no equivalent of ghostty's `background-opacity-cells =
-- false` (config/ghostty/config:68), which is what keeps that accent fully bright
-- there. The cursor is pinned to the same green and stays sharp regardless.
config.macos_window_background_blur = 50
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

-- ============ Clipboard ============
-- Copy already lands on the macOS system clipboard with no extra config:
--   * Mouse selection completes via WezTerm's default CompleteSelection ->
--     "ClipboardAndPrimarySelection"; on macOS (no X11 primary selection) the
--     Clipboard half writes to the system pasteboard, so selecting copies.
--   * Cmd-C copies to the system clipboard, and OSC 52 clipboard *writes* are
--     honored by default, so tmux / Neovim copies inside wezterm reach pbpaste
--     (tmux still needs `set -g set-clipboard on` + an Ms terminfo override to
--     emit OSC 52 — that lives in tmux.conf, not here).
-- Nothing to set: documented so the system-clipboard behavior isn't second-
-- guessed. (Don't override the default mouse bindings just to force "Clipboard";
-- that would mean replicating the whole default mouse table for no gain.)

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
		-- Fallback must track config.window_background_opacity above: on the first
		-- keypress there is no override yet, so a stale default made the opacity
		-- jump instead of step.
		o.window_background_opacity = math.max(0.1, math.min(1.0, (o.window_background_opacity or 0.8) + delta))
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
