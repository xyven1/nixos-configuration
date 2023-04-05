local wezterm = require 'wezterm'

local function merge_tables(...)
  local result = {}
  for _, t in ipairs({...}) do
    for k, v in pairs(t) do
      result[k] = v
    end
  end
  return result
end

local config = {
  keys = {
    { key = 'x', mods = 'CTRL', action = wezterm.action.DisableDefaultAssignment },
  },
  hide_tab_bar_if_only_one_tab = true,
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  window_background_opacity = 0.96
};

return merge_tables(
  config,
  require 'colors',
  -- require 'hyperlink',
  {}
);
