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

    extraPackages = with pkgs; [
      ripgrep
      fzf
      gcc
      nodejs
      rust-bin.beta.latest.default
      gitui
      nixpkgs-fmt
    ];
  };

  home.file = {
    ".config/nvim" = {
      recursive = true;
      source = inputs.neovim-config;
    };
  };
}

