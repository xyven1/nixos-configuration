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
      headset-control = {
        enable = lib.mkEnableOption "Enable Headset Control";
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
      "org/gnome/shell/extensions/HeadsetControl" = lib.mkIf ext-cfg.headset-control.enable {
        headsetcontrol-executable = "${lib.getExe pkgs.headsetcontrol}";
      };
    };
    programs.gnome-shell.enable = true;
    programs.gnome-shell.extensions = lib.concatMap (ext:
      if ext-cfg.${ext.name}.enable
      then [{package = ext.pkg;}]
      else []) [
      {
        name = "paperwm";
        pkg = gnome-exts.paperwm;
      }
      {
        name = "window-title";
        pkg = gnome-exts.window-title-is-back;
      }
      {
        name = "spotify-tray";
        pkg = gnome-exts.spotify-tray;
      }
      {
        name = "freon";
        pkg = gnome-exts.freon;
      }
      {
        name = "gsconnect";
        pkg = gnome-exts.gsconnect;
      }
      {
        name = "tailscale-status";
        pkg = gnome-exts.tailscale-status;
      }
      {
        name = "wallpaper-slideshow";
        pkg = gnome-exts.wallpaper-slideshow;
      }
      {
        name = "blur-my-shell";
        pkg = gnome-exts.blur-my-shell;
      }
      {
        name = "floating-topbar";
        pkg = gnome-exts.user-themes;
      }
      {
        name = "openbar";
        pkg = gnome-exts.open-bar;
      }
      {
        name = "rounded-corners";
        pkg = gnome-exts.rounded-window-corners-reborn;
      }
      {
        name = "headset-control";
        pkg = gnome-exts.headsetcontrol;
      }
    ];
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
      ++ lib.optionals ext-cfg.astra-monitor.enable [
        pkgs.iotop
        pkgs.iw
      ];
    home.sessionVariables = {
      GI_TYPELIB_PATH = lib.mkIf ext-cfg.astra-monitor.enable "${pkgs.libgtop}/lib/girepository-1.0";
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
