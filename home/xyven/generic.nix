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
    bat = {
      enable = true;
      package = pkgs.unstable.bat;
    };
    btop = {
      enable = true;
      package = pkgs.unstable.btop;
      settings = {
        color_theme = "Default";
        theme_background = false;
        vim_keys = true;
        update_ms = 1000;
      };
    };
    eza = {
      enable = true;
      icons = true;
      git = true;
      package = pkgs.unstable.eza;
    };
    fd = {
      enable = true;
      package = pkgs.unstable.fd;
    };
    fzf = {
      enable = true;
      package = pkgs.unstable.fzf;
    };
    gitui = {
      enable = true;
      package = pkgs.unstable.gitui;
    };
    gh = {
      enable = true;
      package = pkgs.unstable.gh;
    };
    ripgrep = {
      enable = true;
      package = pkgs.unstable.ripgrep;
    };
    zoxide = {
      enable = true;
      package = pkgs.unstable.zoxide;
    };
  };

  home = {
    username = "xyven";
    homeDirectory = "/home/xyven";

    packages = with pkgs.unstable; [
      # networking tools
      dig
      iputils
      rustscan
      socat
      wget
      # hardware tools
      pciutils
      usbutils
      # text tools
      jq
      # compression tools
      unzip
      zip
      # other nice-to-haves
      duf
      hyperfine
      ncdu
      pipes-rs
      screen
      tldr
    ];
  };

  home.stateVersion = lib.mkDefault "24.05";
}
