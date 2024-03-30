{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc"];
  boot.initrd.kernelModules = ["i915"];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/91c87923-a783-417f-9a8c-e17427821374";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-292534a5-d4ac-4073-b51c-cc20415bc6f1".device = "/dev/disk/by-uuid/292534a5-d4ac-4073-b51c-cc20415bc6f1";

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/3A59-6482";
    fsType = "vfat";
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
