{
  pkgs,
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
    "nvidia-x11"
    "nvidia-settings"
  ];
  systemd.services.nvidia-suspend.serviceConfig.ExecStart = lib.mkForce "${lib.getExe pkgs.bash} ${config.hardware.nvidia.package.out}/bin/nvidia-sleep.sh suspend";
  systemd.services.nvidia-hibernate.serviceConfig.ExecStart = lib.mkForce "${lib.getExe pkgs.bash} ${config.hardware.nvidia.package.out}/bin/nvidia-sleep.sh hibernate";
  systemd.services.nvidia-resume.serviceConfig.ExecStart = lib.mkForce "${lib.getExe pkgs.bash} ${config.hardware.nvidia.package.out}/bin/nvidia-sleep.sh resume";

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
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
