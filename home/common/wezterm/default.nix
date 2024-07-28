{
  config,
  pkgs, lib,
  ...
}: {
  home.sessionVariables = {
    TERMINAL = "${config.home.profileDirectory}/bin/wezterm";
    XCURSOR_THEME = "Adwaita";
  };

  programs.wezterm = {
    enable = true;
    package = lib.mkDefault pkgs.unstable.wezterm;
  };

  home.file = {
    ".config/wezterm" = {
      recursive = true;
      source = ./config;
    };
  };
}
