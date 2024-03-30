{pkgs, ...}: {
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
    xkb.options = "caps:swapescape";
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  environment.systemPackages = with pkgs; [
    gnome.gnome-session
  ];
  programs.dconf.enable = true;
  environment.gnome.excludePackages = with pkgs.gnome; [
    # baobab # disk usage analyzer
    # file-roller # archive manager
    # gnome-font-viewer
    # gnome-logs
    # gnome-system-monitor
    # nautilus
    # pkgs.gnome-connections
    # pkgs.loupe
    # pkgs.snapshot
    cheese # photo booth
    epiphany # web browser
    evince # document viewer
    geary # email client
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-terminal
    gnome-weather
    pkgs.gnome-console
    pkgs.gnome-photos
    pkgs.gnome-text-editor
    simple-scan # scanner
    totem # video player
    yelp # help browser
  ];

  console.useXkbConfig = true; # applies xkb config to tty terminals
}
