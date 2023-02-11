{ config, pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "${config.home.profileDirectory}/bin/nvim";
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;

    extraPackages = [
      pkgs.ripgrep
      pkgs.fzf
      pkgs.gcc
      pkgs.cargo
      pkgs.rustc
      pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default)
    ];
  };

  home.file = {
    ".config/nvim" = {
      recursive = true;
      source = ../../dotfiles/nvim;
    };
  };
}

