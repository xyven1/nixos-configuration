{ config, pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "${config.home.profileDirectory}/bin/nvim";
  };

  programs.neovim = {
    enable = true;
    # package = pkgs.neovim-nightly.overrideAttrs (_: { CFLAGS = "-O3"; });
    vimAlias = true;
    viAlias = true;

    extraPackages = with pkgs; [
      ripgrep
      fzf
    ];
  };

  home.file = {
    ".config/nvim" = {
      recursive = true;
      source = ../../dotfiles/nvim;
    };
  };
}

