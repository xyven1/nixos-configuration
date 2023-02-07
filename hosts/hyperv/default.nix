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

