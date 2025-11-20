{
  config,
  lib,
  ...
}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  nixpkgs.allowUnfreePackages = [
    "nvidia-settings"
    "nvidia-x11"
  ];

  hardware.nvidia = {
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true;
    prime = {
      offload = {
        enable = lib.mkOverride 990 true;
        enableOffloadCmd = lib.mkIf config.hardware.nvidia.prime.offload.enable true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
