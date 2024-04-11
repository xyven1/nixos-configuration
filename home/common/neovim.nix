{
  inputs,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;

    extraPackages = with pkgs.unstable; [
      ripgrep
      fzf
      gcc
      nodejs
      gitui
      nil
      alejandra
      lua-language-server
    ];
  };

  home.file = {
    ".config/nvim" = {
      recursive = true;
      source = inputs.neovim-config;
    };
  };
}
