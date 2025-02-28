local wezterm = require("wezterm")
local gruvbox_dark = wezterm.get_builtin_color_schemes()["Gruvbox Dark"]

wezterm.on("user-var-changed", function(window, pane, name, value)
	local overrides = window:get_config_overrides() or {}
	-- if name == "ZEN_MODE" and not overrides.line_height then
	if name == "ZEN_MODE" then
		local incremental = value:find("+")
		local number_value = tonumber(value)
		if incremental ~= nil then
			while number_value > 0 do
				window:perform_action(wezterm.action.IncreaseFontSize, pane)
				number_value = number_value - 1
			end
			overrides.enable_tab_bar = true
			-- overrides.line_height = 1.5
		elseif number_value < 0 then
			window:perform_action(wezterm.action.ResetFontSize, pane)
			overrides.font_size = nil
			overrides.enable_tab_bar = true
			-- overrides.line_height = 1.5
		else
			overrides.font_size = number_value
			overrides.enable_tab_bar = true
			-- overrides.line_height = 1.5
		end
	else
		overrides.line_height = nil
	end
	window:set_config_overrides(overrides)
end)
return {
	-- font = wezterm.font("JetBrainsMono Nerd Font Mono"),
	font = wezterm.font_with_fallback({ "Hack Nerd Font", "Symbols Nerd Font" }),
	front_end = "WebGpu",
	window_background_opacity = 1,
	font_size = 21,
	line_height = 1.0,
	-- color_scheme = "Gruvbox Dark",
	color_scheme = "Catppuccin Macchiato",
	window_decorations = "RESIZE",
	max_fps = 120,
	hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = true,
	tab_bar_at_bottom = true,
}
