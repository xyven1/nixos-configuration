{
  pkgs,
  lib,
  ...
}: {
  services = {
    xserver.excludePackages = with pkgs; [xterm];
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-console
    gnome-contacts
    gnome-font-viewer
    gnome-maps
    gnome-music
    gnome-text-editor
    gnome-weather
    orca
    simple-scan
    yelp
  ];

  environment.sessionVariables = {
    TERMINAL = "ghostty";
  };
  environment.systemPackages = with pkgs; [
    eyedropper # color picker
    ghostty # terminal emulator
    (pkgs.writeShellScriptBin "xdg-terminal-exec" ''
      exec ${lib.getExe pkgs.ghostty} -e "$@"
    '')
  ];
}
