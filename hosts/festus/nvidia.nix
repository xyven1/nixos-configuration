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

  systemd.services = let
    append = ["systemd-suspend-then-hibernate.service"];
  in {
    nvidia-suspend.before = append;
    nvidia-suspend.requiredBy = append;
    nvidia-resume.after = append;
    nvidia-resume.requiredBy = append;
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
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
