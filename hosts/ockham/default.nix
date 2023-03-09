{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common/global
    ../common/users/xyven
  ];
  disko.devices = pkgs.callPackage ./disko.nix {
    disks = [ "/dev/sda" ];
  };
  
  users.users.xyven = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9OUNpoctlB+kygCCqcP/YRPDzGcykblU5TKUnfKhY+ (none)"
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh.enable = true;

  networking = {
    hostName = "ockham";
    networkmanager.enable = true;
  };

  system.stateVersion = "22.11";
}
