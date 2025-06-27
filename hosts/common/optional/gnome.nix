{pkgs, ...}: {
  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "";
      xkb.options = "caps:swapescape";
      excludePackages = with pkgs; [xterm];
    };
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  services.gnome.core-apps.enable = false;

  environment.systemPackages = with pkgs; [
    baobab # disk usage analyzer
    # decibels # audio playback
    evince # document viewer
    eyedropper # color picker
    gnome-connections # remote desktop viewer
    file-roller # archive manager
    gnome-logs # log viewer
    gnome-system-monitor # system monitor
    nautilus # file manager
    totem # video player
    loupe # image viewer
    snapshot # screenshot tool

    ghostty # terminal emulator
  ];

  console.useXkbConfig = true; # applies xkb config to tty terminals
}
