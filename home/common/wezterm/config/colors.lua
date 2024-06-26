local module = {}

function module.apply_to_config(config)
  config.colors = {
    ansi = {
      '#1e1e1e',
      '#f44747',
      '#608b4e',
      '#dcdcaa',
      '#569cd6',
      '#c678dd',
      '#56b6c2',
      '#d4d4d4',
    },
    background = '#1e1e1e',
    brights = {
      '#808080',
      '#f44747',
      '#608b4e',
      '#dcdcaa',
      '#569cd6',
      '#c678dd',
      '#56b6c2',
      '#d4d4d4',
    },
    cursor_bg = '#d4d4d4',
    cursor_border = '#d4d4d4',
    cursor_fg = '#1e1e1e',
    foreground = '#d4d4d4',
    selection_bg = '#dcdcaa',
    selection_fg = '#1e1e1e',

    indexed = {
    },
  }
end

return module
