local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

----------------------------------------------------------------
-- 外観
----------------------------------------------------------------
config.color_scheme = "Tokyo Night"
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"Hiragino Sans",
})
config.font_size = 11.0
config.line_height = 1.1

-- 文字色を緑に
config.colors = {
	foreground = "#00ff00",
	background = "#000000",
}

config.window_background_opacity = 0.4
config.macos_window_background_blur = 0
config.window_decorations = "RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.initial_cols = 160
config.initial_rows = 45

-- タブバー
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.tab_max_width = 24

-- 背景画像スライドショー
local BG_INTERVAL = 30 -- 切り替え間隔(秒)
local BG_DIR = wezterm.config_dir .. "/backgrounds"

local bg_files = {}
for _, path in ipairs(wezterm.glob(BG_DIR .. "/*")) do
	if path:lower():match("%.jpe?g$") or path:lower():match("%.png$") or path:lower():match("%.gif$") or path:lower():match("%.webp$") then
		table.insert(bg_files, path)
	end
end
table.sort(bg_files)

local function make_background(file)
	return {
		{ source = { Color = "#000000" }, width = "100%", height = "100%" },
		{
			source = { File = file },
			-- 縦横比を保ったまま Window に収まる最大サイズ (横長の Window なら縦がぴったり合う)
			width = "Contain",
			height = "Contain",
			horizontal_align = "Center",
			vertical_align = "Middle",
			repeat_x = "NoRepeat",
			repeat_y = "NoRepeat",
			hsb = { brightness = 0.5 }, -- 暗くして文字を読みやすくする
		},
	}
end

-- tmux の window 番号 → 背景画像
--   0   : soundonly_S_re.jpg
--   1〜7: soundonly_<番号>_re.jpg
--   他  : NERV 画像
local TMUX_BG_DEFAULT = BG_DIR .. "/2414983186-kabekin_0019_Layer_64-4xjV-1920x1080-MM-100.jpg"
local function tmux_bg_file(n)
	if n == 0 then
		return BG_DIR .. "/soundonly_S_re.jpg"
	elseif n >= 1 and n <= 7 then
		return BG_DIR .. "/soundonly_" .. n .. "_re.jpg"
	end
	return TMUX_BG_DEFAULT
end

-- tmux 内ならその window 番号の画像、tmux 外ならスライドショー
local current = {}
local function apply_background(window, pane)
	local file
	local v = pane:get_user_vars().tmux_window
	local n = v and tonumber(v)
	if n then
		file = tmux_bg_file(n)
	elseif #bg_files > 0 then
		file = bg_files[math.floor(os.time() / BG_INTERVAL) % #bg_files + 1]
	end
	if not file then
		return
	end
	local id = window:window_id()
	if current[id] ~= file then
		current[id] = file
		local overrides = window:get_config_overrides() or {}
		overrides.background = make_background(file)
		window:set_config_overrides(overrides)
	end
end

if #bg_files > 0 then
	config.background = make_background(bg_files[1])
end

wezterm.on("update-status", function(window, pane)
	apply_background(window, pane)
end)
wezterm.on("user-var-changed", function(window, pane, name, _)
	if name == "tmux_window" then
		apply_background(window, pane)
	end
end)

-- 起動時に最大化
wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

----------------------------------------------------------------
-- 動作
----------------------------------------------------------------
config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.native_macos_fullscreen_mode = false

-- 日本語 IME
config.use_ime = true
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

----------------------------------------------------------------
-- キーバインド
----------------------------------------------------------------
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- ペイン分割
	{ key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = false }) },

	-- ペイン移動
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- ペインサイズ変更
	{ key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- タブ操作
	{ key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "[", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },

	-- その他
	{ key = "f", mods = "LEADER", action = act.ToggleFullScreen },
	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
	{ key = "p", mods = "LEADER", action = act.ActivateCommandPalette },
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
}

-- CMD+1〜9 でタブ切り替え
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "CMD",
		action = act.ActivateTab(i - 1),
	})
end

return config
