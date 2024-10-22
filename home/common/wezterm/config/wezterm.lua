local wezterm = require 'wezterm'

local colors = require 'colors'
local smart_splits = wezterm.plugin.require('https://github.com/mrjones2014/smart-splits.nvim')
local bar = wezterm.plugin.require("https://github.com/xyven1/bar.wezterm")
local config = wezterm.config_builder()

config = {
  keys = {
    { key = 'x', mods = 'CTRL', action = wezterm.action.DisableDefaultAssignment },
  },
  -- underline_position = -8,
  term = 'wezterm',
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  audible_bell = "Disabled",
  visual_bell = {
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 300,
  },
  enable_wayland = false,
  window_decorations = "NONE",
  window_background_opacity = 0.9,
  show_new_tab_button_in_tab_bar = false
}

smart_splits.apply_to_config(config, {
  direction_keys = { 'h', 'j', 'k', 'l' },
  modifiers = {
    move = 'CTRL',   -- modifier to use for pane movement, e.g. CTRL+h to move left
    resize = 'META', -- modifier to use for pane resize, e.g. META+h to resize to the left
  },
})

bar.apply_to_config(config, {
  position = 'top',
  separator = {
    field_icon = '',
    right_icon = '',
  },
  modules = {
    pane = { enabled = false },
    clock = { enabled = false },
    username = { enabled = false },
    domain = { enabled = true },
  }
})

colors.apply_to_config(config)
config.colors.visual_bell = 'hsla(0 .35 .3 ' .. config.window_background_opacity .. ')'
config.colors.tab_bar = {
  background = config.colors.background,
  active_tab = {
    bg_color = '#335d80',
    fg_color = config.colors.foreground,
    intensity = 'Bold'
  },
  inactive_tab = {
    bg_color = config.colors.background,
    fg_color = "#a1a1a1"
  },
}

return config
