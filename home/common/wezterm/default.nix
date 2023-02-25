{ inputs, config, pkgs, ... }:
{
  home.sessionVariables = {
    TERMINAL = "${config.home.profileDirectory}/bin/wezterm";
    XCURSOR_THEME = "Adwaita";
  };

  programs.wezterm = {
    enable = true;
  };

  home.file = {
    ".config/wezterm" = {
      recursive = true;
      source = ./config;
    };
  };
}
