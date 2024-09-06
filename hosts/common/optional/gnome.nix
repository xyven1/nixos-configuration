{pkgs, ...}: {
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
    xkb.options = "caps:swapescape";
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    excludePackages = with pkgs; [xterm];
  };
  xdg.terminal-exec = {
    enable = true;
    settings.GNOME = ["wezterm.desktop"];
  };

  services.gnome = {
    core-os-services.enable = true;
    core-utilities.enable = false;
  };

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
  ];

  console.useXkbConfig = true; # applies xkb config to tty terminals
}
