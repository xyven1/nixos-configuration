{ inputs, config, ... }: {
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];
  wayland.windowManager.hyprland.enable = true;
  programs.waybar = {
    enable = true;
  };
}
