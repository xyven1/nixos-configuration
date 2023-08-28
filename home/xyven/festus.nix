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
        spotify-player-latest = super.spotify-player.override {
          withImage = true;
          withLyrics = true;
          withDaemon = true;
        };
      })
      (self: super: {
        google-chrome-wayland = super.unstable.google-chrome.override {
          commandLineArgs = "--disable-features=WaylandFractionalScaleV1";
        };
      })
    ];
  };

  home = {
    packages = with pkgs.unstable; [
      scc
      pkgs.tlpui
      pkgs.wpi-wireless-install # for installing wifi certs
      spotify
      spotify-tray # shows current track and controls in notification area
      gnomeExtensions.spotify-tray # shows current track in tray
      pkgs.spotify-player-latest # terminal spotify client
      wl-clipboard # for clip board support in neovim
      libsForQt5.okular # pdf editor
      libreoffice-qt
      vscode
      vagrant
      zotero

      # unfree
      slack
      pkgs.google-chrome-wayland
      discord
      zoom-us
      parsec-bin
      plex-media-player

      #general dev
      lua-language-server
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  programs.fish = {
    functions = {
      rb = "env -C /etc/nixos/ sudo nixos-rebuild switch --flake .#festus";
      rbh = "env -C /etc/nixos home-manager switch --flake .#xyven@festus";
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
