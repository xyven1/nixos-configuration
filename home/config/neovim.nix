{ config, pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "${config.home.profileDirectory}/bin/nvim";
  };

  programs.neovim = {
    enable = true;
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

