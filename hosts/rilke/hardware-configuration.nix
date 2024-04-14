{ 
  config, 
  lib, 
  modulesPath, 
  ... 
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/6c9d7739-edd2-4b4b-9bb8-7f17927d8d32";
  
  fileSystems."/" = { 
    device = "/dev/disk/by-uuid/7ee93505-7388-4761-b3ce-4d0df07478ea";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F635-1C6D";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [{ device = "/dev/disk/by-uuid/f90b03e4-b511-4b5f-9110-a051cc924923"; }];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
