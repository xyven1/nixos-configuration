{ pkgs, ... }:
let disks = [ "/dev/nvme0n1" ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./services
    (import ./disko.nix {
      disks = disks;
    })
    ../common/global
    ../common/users/xyven
  ];

  users.users.xyven = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9OUNpoctlB+kygCCqcP/YRPDzGcykblU5TKUnfKhY+ blake@gretchen"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqKxEMH57VYdc6hCe25uBkok0KeArgwARqOs1Dw1UBu xyven@festus"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  virtualisation = {
    libvirtd.enable = true;
    docker.enable = true;
  };
  security.polkit.enable = true;
  networking.firewall.allowedTCPPorts = [ 54321 ];

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
    interfaces.eno1.ipv4.addresses = [{
      address = "10.200.10.4";
      prefixLength = 24;
    }];
    defaultGateway = "10.200.10.1";
    nameservers = [ "10.200.10.1" "1.1.1.1" ];
  };

  system.stateVersion = "22.11";
}
