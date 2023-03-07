{ pkgs, inputs, config, ... }:

{
  imports = [
    ./generic.nix
    ../common/font.nix
    ../common/wezterm
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
      discord
      tlpui
      wpi-wireless-install # for installing wifi certs
      spotify
      spotify-tray # shows current track and controls in notification area
      gnomeExtensions.spotify-tray # shows current track in tray
      spotify-player # terminal spotify client
      google-chrome
      wl-clipboard # for clip board support in neovim
      libsForQt5.okular # pdf editor

      unstable.lua-language-server
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  programs.fish = {
    shellAliases = {
      "cd-conf" = "cd /home/xyven/code/nixos-configuration";
    };
    functions = {
      rb = "env -C /home/xyven/code/nixos-configuration sudo nixos-rebuild switch --flake .#festus";
      rbh = "env -C /home/xyven/code/nixos-configuration home-manager switch --flake .#xyven@festus";
      "nvim-update" = "env -C /home/xyven/code/nixos-configuration nix flake lock --update-input neovim-nightly-overlay --update-input neovim-config && rebuild-home";
      "nvim-update-config" = "env -C /home/xyven/code/nixos-configuration nix flake lock --update-input neovim-config && rebuild-home";
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
      ];
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/xyven/.local/background/forest.jpg";
      picture-uri-dark = "file:///home/xyven/.local/background/forest.jpg";
    };
  };
}
