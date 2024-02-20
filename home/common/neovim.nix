{ inputs, pkgs, ... }:

{
  home = {
    packages = with pkgs.unstable; [
      neovide
    ];
  };

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
      rustc
      gitui
      nil
      alejandra
    ];
  };

  home.file = {
    ".config/nvim" = {
      recursive = true;
      source = inputs.neovim-config;
    };
  };
}

