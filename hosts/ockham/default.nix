{ pkgs, ... }:
let disks = [ "/dev/sda" ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./services

    ../common/global
    ../common/users/xyven
  ];
  disko.devices = import ./disko.nix {
    disks = disks;
  };

  users.users.xyven = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9OUNpoctlB+kygCCqcP/YRPDzGcykblU5TKUnfKhY+ (none)"
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.graceful = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
  };
  services.homeManagement.enable = true;

  networking = {
    hostName = "ockham";
    networkmanager.enable = true;
  };

  system.stateVersion = "22.11";
}
