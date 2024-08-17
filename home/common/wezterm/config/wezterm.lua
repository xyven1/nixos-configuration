local wezterm = require 'wezterm'

local colors = require 'colors'
local smart_splits = wezterm.plugin.require('https://github.com/mrjones2014/smart-splits.nvim')
local config = wezterm.config_builder()

config = {
  keys = {
    { key = 'x', mods = 'CTRL', action = wezterm.action.DisableDefaultAssignment },
  },
  -- underline_position = -8,
  term = 'wezterm',
  hide_tab_bar_if_only_one_tab = true,
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  enable_wayland = false;
  window_decorations = "NONE",
  window_background_opacity = 0.9
}

colors.apply_to_config(config)
smart_splits.apply_to_config(config, {
  direction_keys = { 'h', 'j', 'k', 'l' },
  modifiers = {
    move = 'CTRL', -- modifier to use for pane movement, e.g. CTRL+h to move left
    resize = 'META', -- modifier to use for pane resize, e.g. META+h to resize to the left
  },
})

return config
