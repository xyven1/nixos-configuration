{ inputs, config, pkgs, ... }:

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
      pkgs.rust-bin.beta.latest.default
      pkgs.gitui
    ];
  };

  home.file = {
    ".config/nvim" = {
      recursive = true;
      source = inputs.neovim-config;
    };
  };
}

