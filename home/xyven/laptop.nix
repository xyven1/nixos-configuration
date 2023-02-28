{ pkgs, inputs, ... }:

{
  imports = [
    ./generic.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
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
      spotify-player # useful just for quick access to spotify while in the terminal
      ncspot # use ncspot for fully terminal based spotify experience
      google-chrome

      unstable.lua-language-server
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
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

  programs = {
    bash = {
      enable = true;
      shellAliases = {
        "cd-conf" = "cd /home/xyven/code/nixos-configuration";
        rebuild = "pushd . && cd-conf && sudo nixos-rebuild switch --flake .#laptop && popd";
        "rebuild-home" = "pushd . && cd-conf && home-manager switch --flake .#xyven@laptop && popd";
        "nvim-update" = "pushd . && cd-conf && nix flake lock --update-input neovim-nightly-overlay --update-input neovim-config && rebuild-home && popd";
        "nvim-update-config" = "pushd . && cd-conf && nix flake lock --update-input neovim-config && rebuild-home && popd";
      };
    };
    wezterm = {
      enable = true;
    };
  };
}


