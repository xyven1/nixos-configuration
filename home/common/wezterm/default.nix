{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  home.sessionVariables = {
    TERMINAL = "${config.home.profileDirectory}/bin/wezterm";
    XCURSOR_THEME = "Adwaita";
  };

  programs.wezterm = {
    enable = true;
    package = lib.mkDefault inputs.wezterm.packages.${pkgs.system}.default;
  };

  home.file = {
    ".config/wezterm" = {
      recursive = true;
      source = ./config;
    };
  };
}
