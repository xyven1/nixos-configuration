{pkgs, ...}: {
  imports = [
    ./generic.nix
    ../common/font.nix
    ../common/gnome.nix
    ../common/helix.nix
    ../common/wezterm
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  gnome = {
    background = "starship.jpeg";
    extensions = {
      paperwm.enable = true;
      window-title.enable = true;
      spotify-tray.enable = true;
      freon.enable = true;
      gsconnect.enable = true;
    };
  };

  home = {
    packages =
      (with pkgs; [
        wpi-wireless-install # for installing wifi certs
      ])
      ++ (with pkgs.unstable; [
        bottles
        gnome-obfuscate
        libreoffice-qt
        magic-wormhole-rs
        metadata-cleaner
        mousai # music recognition
        neovide
        scc
        spotify
        spotify-player # terminal spotify client
        switcheroo # image converter
        video-trimmer
        vscode
        wike # wikipedia reader
        wl-clipboard # for clip board support in neovim
        zotero

        # unfree
        slack
        obsidian
        (google-chrome.override {
          commandLineArgs = [
            "--enable-features=UseOzonePlatform"
            "--ozone-platform=wayland"
            "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder"
          ];
        })
        discord
        zoom-us
      ]);
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
    "org/gnome/desktop/datetime" = {automatic-timezone = true;};
    "org/gnome/system/location" = {enabled = true;};
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":menu";
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
    };
  };

  home.stateVersion = "22.11";
}
