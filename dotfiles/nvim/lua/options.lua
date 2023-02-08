local o = vim.opt
local g = vim.g

o.expandtab = true -- convert tabs to spaces
o.ignorecase = true -- ignore case in search patterns
o.number = true -- show line numbers
o.relativenumber = true -- show relative line numbers
o.shiftwidth = 2 -- the number of spaces inserted for each indentation
o.smartindent = true -- make indenting smarter again
o.tabstop = 2 -- how many columns a tab counts for
o.termguicolors = true -- use terminal colors
o.foldmethod = 'expr'
o.foldexpr = 'nvim_treesitter#foldexpr()'
o.foldlevelstart = 99
o.pumblend = 30
o.mouse = '' -- disable mouse support

g.loaded_netrw = 1
g.loaded_netrwPlugin = 1
g.suda_smart_edit = 1
g.coq_settings = {
  auto_start = 'shut-up',
  clients = {
    -- tree_sitter = { enabled = false },
    buffers = { enabled = false },
    paths = { preview_lines = 3 }
  },
  display = { icons = { mode = 'short' } },
  keymap = { recommended = false },
}
