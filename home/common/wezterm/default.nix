{
  pkgs,
  lib,
  ...
}: {
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
