{
  inputs,
  pkgs,
  lib,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;

    extraPackages = with pkgs.unstable; [
      # For plugin functionality
      ripgrep
      fzf
      lazygit
      (writeShellScriptBin "nvim-node" "${lib.getExe pkgs.nodejs} $@")
      # LSP & Formatting Providers
      marksman
      lua-language-server
      nil
      alejandra
    ];
  };
  programs.git.ignores = [
    ".lazy.lua"
    ".nvim.lua"
  ];

  xdg.configFile = {
    "nvim" = {
      recursive = true;
      source = inputs.neovim-config;
    };
    "nvim/lua/plugins/treesitter-parsers.lua".text = ''
      vim.opt.runtimepath:append("${pkgs.symlinkJoin {
        name = "treesitter-parsers";
        paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
      }}")
      return {}
    '';
  };
}
