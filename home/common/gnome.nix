{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.gnome = {
    extensions = {
      paperwm = {
        enable = lib.mkEnableOption "Enable PaperWM";
      };
      window-title = {
        enable = lib.mkEnableOption "Enable Window Title";
      };
      spotify-tray = {
        enable = lib.mkEnableOption "Enable Spotify Tray";
      };
      freon = {
        enable = lib.mkEnableOption "Enable Freon";
      };
      gsconnect = {
        enable = lib.mkEnableOption "Enable GSConnect";
      };
      tailscale-status = {
        enable = lib.mkEnableOption "Enable TailScale Status";
      };
    };
    background = lib.mkOption {
      type = lib.types.str;
      default = "forest.jpg";
    };
  };

  config = let
    ext-cfg = config.gnome.extensions;
    cfg = config.gnome;
    gv = lib.hm.gvariant;
    gnome-exts = pkgs.gnomeExtensions;
  in {
    dconf.settings = {
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
      "org/gnome/desktop/default-applications/terminal" = lib.mkIf config.programs.wezterm.enable {
        exec = "${config.home.profileDirectory}/bin/wezterm";
      };
      "org/gnome/desktop/peripherals/keyboard" = {
        delay = lib.hm.gvariant.mkUint32 225;
      };
      "org/gnome/shell" = {
        favorite-apps =
          []
          ++ lib.optionals config.programs.wezterm.enable ["org.wezfurlong.wezterm.desktop"];
        disable-user-extensions = false;
      };
      "org/gnome/desktop/background" = {
        picture-uri = lib.mkDefault "${inputs.backgrounds}/${cfg.background}";
        picture-uri-dark = lib.mkDefault "${inputs.backgrounds}/${cfg.background}";
      };

      "org/gnome/shell/extensions/paperwm" = lib.mkIf ext-cfg.paperwm.enable {
        horizontal-margin = gv.mkInt32 10;
        use-default-background = gv.mkBoolean true;
        vertical-margin = gv.mkInt32 10;
        vertical-margin-bottom = gv.mkInt32 10;
        window-gap = gv.mkInt32 12;
      };
      "org/gnome/shell/extensions/window-title-is-back" = lib.mkIf ext-cfg.window-title.enable {
        colored-icon = true;
        icon-size = lib.hm.gvariant.mkUint32 20;
        show-app = false;
        show-icon = true;
        show-title = true;
      };
      # Extensions
      "org/gnome/shell" = {
        enabled-extensions =
          []
          ++ lib.optionals ext-cfg.paperwm.enable ["paperwm@paperwm.github.com"]
          ++ lib.optionals ext-cfg.window-title.enable ["window-title-is-back@fthx"]
          ++ lib.optionals ext-cfg.spotify-tray.enable ["sp-tray@sp-tray.esenliyim.github.com"]
          ++ lib.optionals ext-cfg.freon.enable ["freon@UshakovVasilii_Github.yahoo.com"]
          ++ lib.optionals ext-cfg.gsconnect.enable ["gsconnect@andyholmes.github.io"]
          ++ lib.optionals ext-cfg.tailscale-status.enable ["tailscale-status@maxgallup.github.com"];
      };
    };
    home.packages =
      []
      ++ lib.optionals ext-cfg.paperwm.enable [gnome-exts.paperwm]
      ++ lib.optionals ext-cfg.window-title.enable [gnome-exts.window-title-is-back]
      ++ lib.optionals ext-cfg.spotify-tray.enable [gnome-exts.spotify-tray]
      ++ lib.optionals ext-cfg.freon.enable [gnome-exts.freon]
      ++ lib.optionals ext-cfg.gsconnect.enable [gnome-exts.gsconnect]
      ++ lib.optionals ext-cfg.tailscale-status.enable [gnome-exts.tailscale-status];
    xdg.configFile."paperwm/user.css" = lib.mkIf ext-cfg.paperwm.enable {
      text = ''
        .paperwm-selection {
            border-radius: 12px 12px 0px 0px;
            border-width: 4px;
            background-color: rgba(0, 0, 0, 0);
        }
      '';
    };
  };
}
