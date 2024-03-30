{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../common/neovim.nix
    ../common/fish.nix
    ../common/starship.nix
    ../common/direnv.nix
    inputs.nix-index-database.hmModules.nix-index
    {
      programs.nix-index-database.comma.enable = true;
    }
  ];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "xyven1";
      userEmail = "git@xyven.dev";
    };
    eza = {
      enable = true;
      icons = true;
      git = true;
    };
    zoxide.enable = true;
    fzf.enable = true;
    gitui.enable = true;
  };

  home = {
    username = "xyven";
    homeDirectory = "/home/xyven";
    sessionVariables = {
      NIX_AUTO_RUN = "1";
    };
    packages = with pkgs; [
      # basic utils
      wget
      unzip
      zip
      dnsutils
      inetutils
      ripgrep
      fzf
      jq
      # other nice-to-haves
      unstable.gh
    ];
  };

  home.stateVersion = "22.11";
}
