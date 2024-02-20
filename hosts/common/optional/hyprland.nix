{inputs, ...}: {
  imports = [
    inputs.hyprland.nixosModules.default
  ];
  programs.hyprland.enable = true;
  programs.xwayland.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    xkbOptions = "caps:swapescape";
  };
  console.useXkbConfig = true;
}
