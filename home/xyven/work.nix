{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
in {
  imports = [
    ../xyven/generic.nix
    ../common/ghostty.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  rbh.profile = "xyven@work";

  nixGL.packages = inputs.nixgl.packages;

  home = {
    username = lib.mkForce "blake";
    packages = with pkgs.unstable; [
      slack
    ];
  };

  neovim.local-config = true;

  programs = {
    ghostty.package = lib.mkForce (config.lib.nixGL.wrap pkgs.unstable.ghostty);
    fish.package = pkgs.fish.override {
      fishEnvPreInit = source: "test -f /etc/profile.d/nix.sh && ${source "/etc/profile.d/nix.sh"}";
    };
    chromium = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.unstable.google-chrome;
    };
    vscode = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.unstable.vscode;
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Yaru-prussiangreen-dark";
      package = pkgs.adw-gtk3;
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      clock-format = "12h";
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
    "org/gnome/desktop/default-applications/terminal" = lib.mkIf config.programs.ghostty.enable {
      exec = lib.getExe config.programs.ghostty.package;
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      delay = lib.hm.gvariant.mkUint32 225;
    };
    "org/gnome/shell" = {
      disable-user-extensions = false;
    };
    "org/gnome/desktop/input-sources" = {
      xkb-options = ["caps:swapescape"];
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };

  home.stateVersion = "25.05";
}
