{ config, ... }:
{
  hardware.opengl =
    {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  };
}
