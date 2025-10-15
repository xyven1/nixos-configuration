{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "vmd" "nvme" "rtsx_pci_sdmmc"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NixOS";
    fsType = "ext4";
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-label/DATA";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-nvme".device = "/dev/disk/by-uuid/292534a5-d4ac-4073-b51c-cc20415bc6f1";

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
