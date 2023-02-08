-- All non plugin related (vim) options
require("options")
-- Plugin management via Packer
require("plugins")
-- Set colorscheme
vim.cmd [[colorscheme vscode]]
-- Vim mappings, see lua/config/which.lua for more mappings
require("mappings")
-- Vim autocommands/autogroups
require("autocmd")
