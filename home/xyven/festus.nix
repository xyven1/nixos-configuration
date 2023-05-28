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
      # (self: super: {
      #   openjdk = super.unstable.jdk17.override {
      #     enableJavaFX = true;
      #   };
      # })
    ];
  };

  home = {
    packages = with pkgs.unstable; [
      fzf
      gitui
      ripgrep
      scc
      pkgs.tlpui
      pkgs.wpi-wireless-install # for installing wifi certs
      spotify
      spotify-tray # shows current track and controls in notification area
      gnomeExtensions.spotify-tray # shows current track in tray
      spotify-player # terminal spotify client
      wl-clipboard # for clip board support in neovim
      libsForQt5.okular # pdf editor
      libreoffice-qt
      vscode

      # unfree
      slack
      google-chrome
      discord
      zoom-us
      parsec-bin
      plex-media-player

      #general dev
      lua-language-server

      #soft eng
      # jetbrains.idea-ultimate
      # openjdk

      #distributed
      vagrant
      gnomeExtensions.gnome-vagrant-indicator # shows vagrant status in tray

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
