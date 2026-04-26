{pkgs, ...}: {
  programs.niri.enable = true;

  services.displayManager.dms-greeter.enable = true;
  services.displayManager.dms-greeter.compositor.name = "niri";

  programs.dms-shell.enable = true;
  programs.dsearch.enable = true;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  environment.defaultPackages = with pkgs; [
    libqalculate
    gpu-screen-recorder
    xwayland-satellite
    bibata-cursors
    qt6Packages.qt6ct
    adw-gtk3
    material-symbols
  ];

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  xdg = {
    autostart.enable = true;
    menus.enable = true;
    mime.enable = true;
    icons.enable = true;
  };

  systemd.user.services.niri-flake-polkit = {
    description = "PolicyKit Authentication Agent provided by niri-flake";
    wantedBy = ["niri.service"];
    after = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
