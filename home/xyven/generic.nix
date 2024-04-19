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
      package = pkgs.unstable.git;
    };
    eza = {
      enable = true;
      icons = true;
      git = true;
      package = pkgs.unstable.eza;
    };
    zoxide = {
      enable = true;
      package = pkgs.unstable.zoxide;
    };
    fzf = {
      enable = true;
      package = pkgs.unstable.fzf;
    };
    gitui = {
      enable = true;
      package = pkgs.unstable.gitui;
    };
  };

  home = {
    username = "xyven";
    homeDirectory = "/home/xyven";
    sessionVariables = {
      # NIX_AUTO_RUN = "1";
    };
    packages = with pkgs.unstable; [
      # networking tools
      dnsutils
      inetutils
      nmap
      wget
      # text tools
      jq
      ripgrep
      # compression tools
      unzip
      zip
      # other nice-to-haves
      gh
      hyperfine
      ncdu
      pipes-rs
    ];
  };

  home.stateVersion = lib.mkDefault "24.05";
}
