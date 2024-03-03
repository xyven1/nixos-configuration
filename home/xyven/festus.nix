{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./generic.nix
    ../common/font.nix
    ../common/wezterm
    ../common/helix.nix
    # ../common/hyprland.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "electron-25.9.0"
    ];
    overlays = [
      (self: super: {
        spotify-player = super.pkgs.unstable.spotify-player.override {
          withSixel = false;
          withNotify = false;
        };
      })
      (self: super: {
        google-chrome = super.pkgs.unstable.google-chrome.override {
          commandLineArgs = [
            "--use-angle=vulkan"
          ];
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
      gnomeExtensions.paperwm # tiling window manager
      pkgs.spotify-player # terminal spotify client
      wl-clipboard # for clip board support in neovim
      libsForQt5.okular # pdf editor
      libreoffice-qt
      thunderbird
      vscode
      vagrant
      zotero

      # unfree
      slack
      obsidian
      pkgs.google-chrome
      # firefox
      discord
      zoom-us
      parsec-bin
      plex-media-player

      #general dev
      lua-language-server
    ];
    sessionVariables = {
      # NIXOS_OZONE_WL = "1";
    };
  };

  programs.sioyek = {
    enable = true;
    package = pkgs.sioyek;
    config = {
      "ui_font" = "JetBrainsMono Nerd Font";
      # "status_bar_font_size" = "30";
      # "font_size" = "30";
      "default_dark_mode" = "1";
      "inverted_horizontal_scrolling" = "1";
      "super_fast_search" = "1";
      "case_sensitive_search" = "0";
      "custom_background_color" = ".2 .2 .2";
      "custom_text_color" = ".9 .9 .9";
      "custom_color_mode_empty_background_color" = ".1 .1 .1";
      "custom_color_contrast" = "1";
    };
  };

  programs.fish = {
    shellAliases = {
      sp = "spotify_player";
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
    "org/gnome/desktop/peripherals/keyboard" = {
      delay = lib.hm.gvariant.mkUint32 225;
    };
    "org/gnome/shell/extensions/paperwm" = {
      "use-default-background" = true;
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "org.wezfurlong.wezterm.desktop"
        "google-chrome.desktop"
        "obsidian.desktop"
        "discord.desktop"
      ];
      disable-user-extensions = false;
      enabled-extensions = [
        "sp-tray@sp-tray.esenliyim.github.com"
        "gnome-vagrant-indicator@gnome-shell-exstensions.fffilo.github.com"
        "paperwm@paperwm.github.com"
      ];
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/xyven/.local/background/forest.jpg";
      picture-uri-dark = "file:///home/xyven/.local/background/forest.jpg";
    };
  };
}
