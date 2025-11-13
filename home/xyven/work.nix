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

  targets.genericLinux = {
    enable = true;
    nixGL = {
      vulkan.enable = true;
      packages = inputs.nixgl.packages;
      installScripts = ["mesa"];
    };
  };
  home = {
    username = lib.mkForce "blake";
    packages = with pkgs.unstable; [
      slack
    ];
  };

  neovim.local-config = true;

  programs = {
    ghostty.package = let
      pkg = pkgs.unstable.ghostty;
    in
      lib.mkForce ((config.lib.nixGL.wrap pkg).overrideAttrs (old: {
        buildCommand =
          old.buildCommand
          + ''
            shopt -s nullglob globstar
            for dsk in "$out"/share/**/*.service ; do
              if ! grep -q "${pkg.out}" "$dsk"; then
                continue
              fi
              src="$(readlink "$dsk")"
              rm "$dsk"
              sed "s|${pkg.out}|$out|g" "$src" > "$dsk"
            done
            shopt -u nullglob globstar
          '';
      }));
    fish.package = pkgs.fish.override {
      fishEnvPreInit = source: ''
        ${source "${
          if config.nix.package == null
          then pkgs.nix
          else config.nix.package
        }/etc/profile.d/nix.sh"}
        ${source "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"}
      '';
    };
    chromium = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.unstable.google-chrome;
    };
    vscode = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.unstable.vscode;
    };
    neovim.package = lib.mkForce pkgs.unstable.neovim-unwrapped;
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
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };

  home.stateVersion = "25.05";
}
