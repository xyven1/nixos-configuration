{ inputs, config, pkgs, ... }:
{
  home.sessionVariables = {
    TERMINAL = "wezterm";
  };

  programs.wezterm = {
    enable = true;
  };

  home.file = {
    ".config/wezterm/" = {
      recursive = true;
      source = ./config;
    };
  };
}
