{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    xkbOptions = "caps:swapescape";
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
  ];
  programs.dconf.enable = true;
  environment.gnome.excludePackages = with pkgs.gnome; [
    cheese # photo booth
    epiphany # web browser
    gedit # text editor
    simple-scan # scanner
    yelp # help browser
    evince # document viewer
    file-roller # archive manager
    geary # email client

    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-weather
    gnome-terminal

    pkgs.gnome-text-editor
    pkgs.gnome-photos
  ];

  console.useXkbConfig = true; # applies xkb config to tty terminals
}
