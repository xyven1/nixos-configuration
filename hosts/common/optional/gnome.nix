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

  services.gnome.core-apps.enable = false;

  environment.sessionVariables = {
    TERMINAL = "ghostty";
  };
  environment.systemPackages = with pkgs; [
    baobab # disk usage analyzer
    decibels # audio playback
    evince # document viewer
    eyedropper # color picker
    gnome-connections # remote desktop viewer
    file-roller # archive manager
    gnome-disk-utility # disk manager
    gnome-logs # log viewer
    gnome-system-monitor # system monitor
    nautilus # file manager
    totem # video player
    loupe # image viewer
    snapshot # screenshot tool

    ghostty # terminal emulator
    (pkgs.writeShellScriptBin "xdg-terminal-exec" ''
      ${lib.getExe pkgs.ghostty} -e "$@"
    '')
  ];
}
