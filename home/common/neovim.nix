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
      lua-language-server
      nil
      alejandra
    ];
  };
  programs.git.ignores = [
    ".lazy.lua"
    ".nvim.lua"
  ];

  xdg.configFile."nvim" = {
    recursive = true;
    source = inputs.neovim-config;
  };
}
