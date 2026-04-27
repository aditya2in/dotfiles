-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.color_scheme = "Batman"

config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 14

-- config.enable_tab_bar = false

-- config.window_decorations = " RESIZE"

config.window_background_opacity = 1.0
config.macos_window_background_blur = 9

-- Add this line to disable the quit confirmation prompt
config.window_close_confirmation = "NeverPrompt"

-- Add this line to enable blur on Linux:
-- config.window_background_blur = true

-- Tab Bar Settings
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false

-- Match Tab Bar colors to the background for a "transparent" look
config.colors = {
	tab_bar = {
		background = "#121212",
		active_tab = {
			bg_color = "#333333",
			fg_color = "#bebebe",
		},
		inactive_tab = {
			bg_color = "#121212",
			fg_color = "#8a8a8d",
		},
		inactive_tab_hover = {
			bg_color = "#1e1e2e",
			fg_color = "#bebebe",
		},
		new_tab = {
			bg_color = "#121212",
			fg_color = "#bebebe",
		},
		new_tab_hover = {
			bg_color = "#333333",
			fg_color = "#ffffff",
		},
	},
	foreground = "#bebebe",
	background = "#121212",
	cursor_bg = "#47FF9C",
	cursor_border = "#47FF9C",
	cursor_fg = "#011423",
	selection_bg = "#033259",
	selection_fg = "#CBE0F0",
	ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
	brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
}

-- and finally, return the configuration to wezterm
return config
