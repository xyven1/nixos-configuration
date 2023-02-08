local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

vim.g.mapleader = " "

local function get_config(name)
  return function()
    require("config/" .. name)
  end
end

require("lazy").setup({
  -- Performance
  { 'dstein64/vim-startuptime', cmd = "StartupTime" },
  -- Coding productivity
  { 'ms-jpq/coq_nvim' },
  { 'ms-jpq/coq.artifacts' },
  { 'ms-jpq/coq.thirdparty', config = function()
    require("coq_3p") {
      { src = "copilot", short_name = "COP", accept_key = "<c-f>" }
    }
  end },
  { 'williamboman/mason-lspconfig.nvim',
    opts = {
      ensure_installed = {}
    },
    dependencies = { "williamboman/mason.nvim" } },
  { 'jayp0521/mason-nvim-dap.nvim',
    opts = {
      automatic_setup = true,
    },
    dependencies = { "williamboman/mason.nvim" } },
  { 'williamboman/mason.nvim', config = true },
  { 'neovim/nvim-lspconfig',
    config = get_config("lsp"),
    dependencies = "coq_nvim" },
  { 'mfussenegger/nvim-dap', config = get_config("dap") },
  { 'theHamsta/nvim-dap-virtual-text', config = true },
  { 'github/copilot.vim' },
  { 'nvim-treesitter/nvim-treesitter', config = get_config("treesitter") },
  { 'nvim-treesitter/nvim-treesitter-textobjects' },
  { 'nvim-treesitter/playground', cmd = 'TSPlaygroundToggle' },
  { 'ray-x/lsp_signature.nvim',
    opts = {
      hint_enable = false,
      toggle_key = '<M-x>' -- toggle signature on and off in insert mode,  e.g. toggle_key = '<M-x>'
    } },
  -- UI plugins
  { 'nvim-tree/nvim-web-devicons' },
  { 'Mofiqul/vscode.nvim',
    opts = {
      italic_comments = true,
    },
    priority = 1000 },
  { 'folke/tokyonight.nvim',
    lazy = true,
    priority = 1000 },
  { 'martinsione/darkplus.nvim',
    lazy = true,
    priority = 1000 },
  { 'olimorris/onedarkpro.nvim',
    lazy = true,
    priority = 1000 },
  { 'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = true,
        theme = 'auto',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {},
        always_divide_middle = true,
        globalstatus = true,
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename', 'lsp_progress' },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
      },
      tabline = {},
      extensions = {}
    },
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  { 'arkav/lualine-lsp-progress' },
  { 'rcarriga/nvim-dap-ui',
    keys = {
      { "<F4>", require("dapui").toggle },
    },
    config = true },
  { 'akinsho/bufferline.nvim',
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
          local s = ""
          local level_str = {
            error = " ", -- warning = " ", info = " ", hint = " ",
          }
          for e, n in pairs(diagnostics_dict) do
            if n > 0 and level_str[e] ~= nil then
              s = s .. n .. level_str[e]
            end
          end
          return s
        end,
        offsets = { { filetype = "NvimTree", text = "File Explorer", text_align = "left" } },
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = "none",
      }
    } },
  { 'kevinhwang91/nvim-bqf', ft = 'qf' },
  { 'folke/todo-comments.nvim', dependencies = { "nvim-lua/plenary.nvim" }, config = true },
  { 'glepnir/dashboard-nvim',
    event = 'VimEnter',
    opts = {
      theme = 'doom',
      config = {
        week_header = {
          enable = true,
        },
        center = {
          { icon = '  ',
            desc = 'Open current directory\'s session       ',
            key = 's',
            action = 'SessionManager load_current_dir_session' },
          { icon = '  ',
            desc = 'Open lastest session                    ',
            key = 'l',
            action = 'SessionManager load_last_session' },
          { icon = '  ',
            desc = 'Recently opened sessions                ',
            key = 'r',
            action = 'SessionManager load_session' },
          { icon = '  ',
            desc = 'Open Personal dotfiles                  ',
            key = 'd',
            action = 'cd ' .. os.getenv('HOME') .. '/.config/nvim/ | SessionManager load_current_dir_session' },
        },
      },
    },
    dependencies = { 'nvim-tree/nvim-web-devicons' } },
  { 'glepnir/lspsaga.nvim',
    config = true,
    event = "BufRead",
    dependencies = { "nvim-tree/nvim-web-devicons" } },
  -- Navigation plugins
  { 'ggandor/lightspeed.nvim', keys = { "s", "S" } },
  { 'ibhagwan/fzf-lua', cmd = "FzfLua", dependencies = { 'nvim-tree/nvim-web-devicons' } },
  { 'nvim-tree/nvim-tree.lua',
    cmd = { "NvimTreeOpen", "NvimTreeToggle" },
    opts = {
      disable_netrw = true,
      hijack_cursor = true,
      hijack_unnamed_buffer_when_opening = true,
      sync_root_with_cwd = true,
      view = {
        mappings = {
          list = {
            { key = "<S-v>", action = "vsplit" },
            { key = "<S-x>", action = "split" },
          },
        },
      },
      renderer = {
        indent_markers = {
          enable = true,
        },
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
      },
    },
  },
  { 'folke/trouble.nvim',
    cmd = { "Trouble", "TroubleToggle" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = true },
  { 'simrat39/symbols-outline.nvim', cmd = { "SymbolsOutline" }, config = true },

  -- Miscellanious plugins
  { 'lambdalisue/suda.vim' },
  { 'kazhala/close-buffers.nvim', config = true },
  { 'numToStr/Comment.nvim', config = true },
  { 'andweeb/presence.nvim' },
  { 'Shatur/neovim-session-manager', opts = {
    autoload_mode = require('session_manager.config').AutoloadMode.Disabled,
  } },
  { 'smjonas/inc-rename.nvim', config = true },
  { 'windwp/nvim-autopairs', opts = {
    disable_filetype = { "telescopeprompt" },
    check_ts = true,
    ts_config = {
    },
    map_bs = false,
    map_cr = false,
  }, },
  { 'lewis6991/gitsigns.nvim',
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufReadPre",
    config = true }
}, {

})
