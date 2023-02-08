function Split(s, delimiter)
  local result = {};
  for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match);
  end
  return result;
end

local dap = require("dap")

require 'mason-nvim-dap'.setup_handlers {
  function(source_name)
    -- all sources with no handler get passed here
    require('mason-nvim-dap.automatic_setup')(source_name)
  end,
  codelldb = function(source_name)
    dap.adapters.lldb = {
      type = 'executable',
      command = 'codelldb';
    }
    dap.configurations.cpp = {
      {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
          local path = vim.fn.getcwd() .. "/config.txt"
          if vim.fn.filereadable(path) ~= 0 then
            print("Found config.txt")
            local config = vim.fn.readfile(path)
            for _, line in ipairs(config) do
              if line:match("^program") then
                return line:match("^program%s*=%s*(.+)")
              end
            end
          end
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = function()
          local path = vim.fn.getcwd() .. "/config.txt"
          if vim.fn.filereadable(path) ~= 0 then
            local config = vim.fn.readfile(path)
            for i, line in ipairs(config) do
              -- check for line with args and opening curly brace
              if line:match("^args") and line:match("{") then
                -- read lines until we find closing curly brace
                local args = {}
                for j = i + 1, #config do
                  if config[j]:match("^%s*%}") then
                    break
                  end
                  table.insert(args, config[j]:match("^%s*(.+)"))
                end
                return args
              end
            end
          end
          local args = vim.fn.input('Arguments: ', '')
          return Split(args, ' ')
        end,
        runInTerminal = false,
        postRunCommands = { 'process handle -p true -s false -n false SIGWINCH' }
      },
    }

    dap.configurations.c = dap.configurations.cpp
    dap.configurations.rust = dap.configurations.cpp
  end
}
