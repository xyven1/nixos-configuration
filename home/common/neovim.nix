{
  inputs,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withNodeJs = true;

    extraPackages = with pkgs.unstable; [
      ripgrep
      fzf
      lazygit
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
