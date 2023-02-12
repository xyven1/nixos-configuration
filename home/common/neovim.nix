{ inputs, config, pkgs, ... }:

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
      gcc
      nodejs
      rust-bin.beta.latest.default
      gitui
    ];
  };

  home.file = {
    ".config/nvim" = {
      recursive = true;
      source = inputs.neovim-config;
    };
  };
}

