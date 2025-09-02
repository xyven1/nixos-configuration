{pkgs, ...}: {
  imports = [
    ./generic.nix
    ../common/ghostty.nix
    ../common/gnome.nix
    ../common/helix.nix
    ../common/wezterm
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  gnome = {
    background = "forest.jpg";
    extensions = {
      paperwm.enable = true;
      window-title.enable = true;
      spotify-tray.enable = true;
      astra-monitor.enable = true;
      blur-my-shell.enable = true;
      headset-control.enable = true;
      floating-topbar = {
        enable = true;
        margin = 6;
      };
    };
  };
  programs.gnome-shell.extensions = with pkgs.gnomeExtensions; [
    {package = headsetcontrol;}
  ];

  home = {
    packages = with pkgs.unstable; [
      exercism
      gnome-obfuscate
      junction # application picker
      libreoffice-qt
      magic-wormhole-rs
      metadata-cleaner
      mousai # music recognition
      neovide
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
      plex-desktop
      # games
      prismlauncher
    ];
    # sessionVariables.NIXOS_OZONE_WL = "1";
    sessionVariables.NEOVIDE_FRAME = "none";
  };

  programs.sioyek = {
    enable = true;
    config = {
      "ui_font" = "JetBrainsMono Nerd Font";
      "default_dark_mode" = "1";
      "super_fast_search" = "1";
      "case_sensitive_search" = "0";
      "custom_background_color" = ".2 .2 .2";
      "custom_text_color" = ".9 .9 .9";
      "custom_color_mode_empty_background_color" = ".1 .1 .1";
      "custom_color_contrast" = "1";
    };
  };

  programs.fish = {
    shellAbbrs = {
      sp = "spotify_player";
    };
  };

  dconf.settings = {
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "google-chrome.desktop"
        "obsidian.desktop"
        "discord.desktop"
      ];
    };
  };

  home.stateVersion = "24.05";
}
