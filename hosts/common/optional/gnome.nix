{
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    xkbOptions = "caps:swapescape";
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  console.useXkbConfig = true; # applies xkb config to tty terminals
}
