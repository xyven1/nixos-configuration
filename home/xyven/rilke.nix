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
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  home = {
    packages =
      (with pkgs; [
        neovide-nightly
      ]) ++
      (with pkgs.unstable; [
        exercism
        gnome-obfuscate
        junction # application picker
        libreoffice-qt
        magic-wormhole-rs
        metadata-cleaner
        mousai # music recognition
        scc
        spotify
        spotify-player # terminal spotify client
        spotify-tray # shows current track and controls in notification area
        switcheroo # image converter
        texliveFull
        video-trimmer
        virt-manager
        vscode
        wike # wikipedia reader
        xclip # for clip board support in neovim

        # unfree
        slack
        obsidian
        google-chrome
        discord
        zoom-us
        parsec-bin
        plex-media-player
      ])
      ++ (with pkgs.unstable.gnomeExtensions; [
        freon
        paperwm
        spotify-tray
        window-title-is-back
      ]);
    # sessionVariables.NIXOS_OZONE_WL = "1";
    sessionVariables.NEOVIDE_FRAME = "none";
  };

  programs.sioyek = {
    enable = true;
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

  xdg.configFile."paperwm/user.css".text = ''
    .paperwm-selection {
        border-radius: 12px 12px 0px 0px;
        border-width: 4px;
        background-color: rgba(0, 0, 0, 0);
    }
  '';
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/nautilus/list-view" = {
      default-zoom-level = "medium";
      use-tree-view = true;
    };
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
      search-view = "list-view";
    };
    "org/gnome/desktop/default-applications/terminal" = {
      exec = "/etc/profiles/per-user/xyven/bin/wezterm";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      delay = lib.hm.gvariant.mkUint32 225;
    };
    "org/gnome/shell/extensions/paperwm" = {
      use-default-background = true;
    };
    "org/gnome/shell/extensions/window-title-is-back" = {
      colored-icon = true;
      icon-size = lib.hm.gvariant.mkUint32 20;
      show-app = false;
      show-icon = true;
      show-title = true;
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
        "freon@UshakovVasilii_Github.yahoo.com"
        "paperwm@paperwm.github.com"
        "window-title-is-back@fthx"
      ];
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/xyven/.local/background/forest.jpg";
      picture-uri-dark = "file:///home/xyven/.local/background/forest.jpg";
    };
  };

  home.stateVersion = "24.05";
}
