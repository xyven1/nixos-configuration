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
      astra-monitor = {
        enable = lib.mkEnableOption "Enable Astra Monitor";
      };
      blur-my-shell = {
        enable = lib.mkEnableOption "Enable Blur My Shell";
      };
      openbar = {
        enable = lib.mkEnableOption "Enable Open Bar";
      };
      floating-topbar = {
        enable = lib.mkEnableOption "Enable Floating Topbar";
        margin = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "Margin for the floating topbar";
        };
      };
      rounded-corners = {
        enable = lib.mkEnableOption "Enable Rounded Corners";
      };
      wallpaper-slideshow = {
        enable = lib.mkEnableOption "Enable Wallpaper Slideshow";
      };
    };
    background = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = let
    ext-cfg = config.gnome.extensions;
    cfg = config.gnome;
    gv = lib.gvariant;
    gnome-exts = pkgs.gnomeExtensions;
  in {
    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
    };
    qt = {
      enable = true;
      platformTheme = "adwaita";
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
      "org/gnome/mutter" = {
        experimental-features = gv.mkArray [
          "scale-monitor-framebuffer"
          "xwayland-native-scaling"
        ];
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
      "org/gnome/desktop/background" = lib.mkIf (cfg.background != null) {
        picture-uri = lib.mkDefault "${inputs.backgrounds}/${cfg.background}";
        picture-uri-dark = lib.mkDefault "${inputs.backgrounds}/${cfg.background}";
      };
      "org/gnome/shell/extensions/paperwm" = lib.mkIf ext-cfg.paperwm.enable {
        horizontal-margin = gv.mkInt32 6;
        use-default-background = gv.mkBoolean true;
        selection-border-size = gv.mkInt32 5;
        vertical-margin = gv.mkInt32 (
          if ext-cfg.floating-topbar.enable
          then 0
          else 6
        );
        vertical-margin-bottom = gv.mkInt32 6;
        selection-border-radius-top = gv.mkInt32 4;
        selection-border-radius-bottom = gv.mkInt32 4;
        window-gap = gv.mkInt32 6;
      };
      "org/gnome/shell/extensions/window-title-is-back" = lib.mkIf ext-cfg.window-title.enable {
        colored-icon = true;
        icon-size = lib.hm.gvariant.mkUint32 20;
        show-app = false;
        show-icon = true;
        show-title = true;
      };
      "org/gnome/shell/extensions/user-theme" = lib.mkIf ext-cfg.floating-topbar.enable {
        name = "floating-topbar";
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
          ++ lib.optionals ext-cfg.tailscale-status.enable ["tailscale-status@maxgallup.github.com"]
          ++ lib.optionals ext-cfg.wallpaper-slideshow.enable ["azwallpaper@azwallpaper.gitlab.com"]
          ++ lib.optionals ext-cfg.blur-my-shell.enable ["blur-my-shell@aunetx"]
          ++ lib.optionals ext-cfg.openbar.enable ["openbar@neuromorph"]
          ++ lib.optionals ext-cfg.openbar.enable ["openbar@neuromorph"]
          ++ lib.optionals ext-cfg.floating-topbar.enable ["user-theme@gnome-shell-extensions.gcampax.github.com"]
          ++ lib.optionals ext-cfg.rounded-corners.enable ["rounded-window-corners@fxgn"]
          ++ lib.optionals ext-cfg.astra-monitor.enable ["monitor@astraext.github.io"];
      };
    };
    home.packages =
      [
        (pkgs.stdenv.mkDerivation rec {
          name = "floating-topbar";
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/share/themes/${name}/gnome-shell
            echo '#panel {
              margin: ${toString ext-cfg.floating-topbar.margin}px;
            }' > $out/share/themes/${name}/gnome-shell/gnome-shell.css
          '';
        })
      ]
      ++ lib.optionals ext-cfg.paperwm.enable [gnome-exts.paperwm]
      ++ lib.optionals ext-cfg.window-title.enable [gnome-exts.window-title-is-back]
      ++ lib.optionals ext-cfg.spotify-tray.enable [gnome-exts.spotify-tray]
      ++ lib.optionals ext-cfg.freon.enable [gnome-exts.freon]
      ++ lib.optionals ext-cfg.gsconnect.enable [gnome-exts.gsconnect]
      ++ lib.optionals ext-cfg.tailscale-status.enable [gnome-exts.tailscale-status]
      ++ lib.optionals ext-cfg.wallpaper-slideshow.enable [gnome-exts.wallpaper-slideshow]
      ++ lib.optionals ext-cfg.blur-my-shell.enable [gnome-exts.blur-my-shell]
      ++ lib.optionals ext-cfg.openbar.enable [gnome-exts.open-bar]
      ++ lib.optionals ext-cfg.floating-topbar.enable [gnome-exts.user-themes]
      ++ lib.optionals ext-cfg.rounded-corners.enable [gnome-exts.rounded-window-corners-reborn]
      ++ lib.optionals ext-cfg.astra-monitor.enable [
        gnome-exts.astra-monitor
        pkgs.iotop
        pkgs.iw
      ];
    home.sessionVariables = lib.mkIf ext-cfg.astra-monitor.enable {
      GI_TYPELIB_PATH = "${pkgs.libgtop}/lib/girepository-1.0";
    };
    xdg.configFile."paperwm/user.css" = lib.mkIf ext-cfg.paperwm.enable {
      text = ''
        .paperwm-selection {
            border-width: ${toString (
          if ext-cfg.floating-topbar.enable
          then 0
          else 2
        )}px;
            background-color: rgba(0, 0, 0, 0);
        }
      '';
    };
  };
}
