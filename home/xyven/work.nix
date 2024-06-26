{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  nixGLWrap = pkg:
    pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      for bin in ${pkg}/bin/*; do
       wrapped_bin=$out/bin/$(basename $bin)
       echo "exec ${lib.getExe pkgs.nixgl.nixGLIntel} $bin \"\$@\"" > $wrapped_bin
       chmod +x $wrapped_bin
      done
    '';
in {
  imports = [
    ../xyven/generic.nix
    ../common/font.nix
    ../common/wezterm
    ../common/helix.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.nixgl.overlay
    ];
  };

  rbh.profile = "xyven@work";

  home = {
    username = lib.mkForce "bbruell";
    packages = with pkgs.unstable; [
      (nixGLWrap neovide)
      libreoffice-qt
      scc
      vscode
      wike
      xclip
      firefox
      docker
      glab
    ];
    sessionVariables.NEOVIDE_FRAME = "none";
    sessionVariables.TERMINFO_DIRS = "${pkgs.wezterm.passthru.terminfo}/share/terminfo";
  };

  programs = {
    wezterm.package = lib.mkForce (nixGLWrap pkgs.unstable.wezterm);
    fish.package = pkgs.fish.override {
      fishEnvPreInit = source: source "/etc/profile.d/nix.sh";
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
      exec = "${config.home.homeDirectory}/.nix-profile/bin/wezterm";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
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
      ];
      disable-user-extensions = false;
      enabled-extensions = [
        "paperwm@paperwm.github.com"
        "window-title-is-back@fthx"
      ];
    };
    "org/gnome/desktop/background" = {
      picture-uri = "${inputs.backgrounds}/forest.jpg";
      picture-uri-dark = "${inputs.backgrounds}/forest.jpg";
    };
  };

  home.stateVersion = "24.05";
}
