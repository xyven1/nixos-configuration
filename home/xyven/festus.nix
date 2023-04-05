{ pkgs, inputs, config, ... }:

{
  imports = [
    ./generic.nix
    ../common/font.nix
    ../common/wezterm
    # ../common/hyprland.nix
  ];

  nixpkgs = {
    overlays = [
      (self: super: {
        spotify-player = super.spotify-player.override {
          withImage = true;
          withLyrics = true;
        };
      })
    ];
  };

  home = {
    packages = with pkgs; [
      wezterm
      fzf
      gitui
      ripgrep
      scc
      tlpui
      wpi-wireless-install # for installing wifi certs
      spotify
      spotify-tray # shows current track and controls in notification area
      gnomeExtensions.spotify-tray # shows current track in tray
      spotify-player # terminal spotify client
      # wl-clipboard # for clip board support in neovim
      xclip
      libsForQt5.okular # pdf editor
      libreoffice-qt

      # unfree
      slack
      google-chrome
      discord
      zoom-us
      unstable.parsec-bin

      #general dev
      unstable.lua-language-server

      #soft eng
      jetbrains.idea-ultimate
      unstable.nodejs-19_x # for github copilot in intellij
      unstable.jdk17
      scenebuilder19

      #distributed
      unstable.vagrant
      unstable.gnomeExtensions.gnome-vagrant-indicator # shows vagrant status in tray

      #id2050
      zotero
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  programs.fish = {
    functions = {
      rb = "env -C /etc/nixos/ sudo nixos-rebuild switch --flake .#festus";
      rbh = "env -C /etc/nixos home-manager switch --flake .#xyven@festus";
      "nvim-update" = "env -C /etc/nixos nix flake lock --update-input neovim-nightly-overlay --update-input neovim-config && rebuild-home";
      "nvim-update-config" = "env -C /etc/nixos nix flake lock --update-input neovim-config && rebuild-home";
    };
    shellAbbrs = {
      "conf" = "/etc/nixos";
    };
  };

  home.file = {
    ".local/background/" = {
      recursive = true;
      source = inputs.backgrounds;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/default-applications/terminal" = {
      exec = "/etc/profiles/per-user/xyven/bin/wezterm";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "google-chrome.desktop"
        "org.wezfurlong.wezterm.desktop"
      ];
      disable-user-extensions = false;
      enabled-extensions = [
        "sp-tray@sp-tray.esenliyim.github.com"
        "gnome-vagrant-indicator@gnome-shell-exstensions.fffilo.github.com"
      ];
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/xyven/.local/background/forest.jpg";
      picture-uri-dark = "file:///home/xyven/.local/background/forest.jpg";
    };
  };
}
