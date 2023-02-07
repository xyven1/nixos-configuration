{ inputs, config, pkgs, lib, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    ./hardware-configuration.nix
  ];

  boot = {
	  kernelPackages = pkgs.linuxKernel.packages.linux_zen;
	  binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    zfsSupport = true;
  };
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.devNodes = "/dev/disk/by-partuuid";
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  networking = {
    hostName = "hyperv";
  };

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      openFirewall = false;
    };
  };
  system.stateVersion = "22.05";
}

