{config, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  nixpkgs.config.nvidia.acceptLicense = true;
  services.xserver.videoDrivers = ["nvidia"];
  nixpkgs.allowUnfreePackages = [
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-kernel-modules"
  ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  };
}
