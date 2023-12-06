{ inputs, pkgs, lib, ... }:
let disks = [ "/dev/nvme0n1" ];
in
{
  imports = [
    inputs.vscode-server.nixosModules.default
    ./hardware-configuration.nix
    ./nvidia.nix
    ./services
    (import ./disko.nix {
      disks = disks;
    })
    ../common/global
    ../common/users/xyven
    ../common/users/gob
  ];

  users.users.xyven = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9OUNpoctlB+kygCCqcP/YRPDzGcykblU5TKUnfKhY+ blake@gretchen"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqKxEMH57VYdc6hCe25uBkok0KeArgwARqOs1Dw1UBu xyven@festus"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEq5E8HRvArWWc5F9+qI6AuU9Kh1CoJ8/lZ+jErnQAOC xyven@BLAKE-XPS17"
    ];
  };
  users.users.gob = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJ9kEMLVISMvJbcuy6WX7ssoWt9UZ8vq/KCOHaB8S78C0Gq6qG94sJwxyQpuZvfFjEEXjC/qay+iJfNWBFh5klLaG9pqS1UIBNTNLvZVZoJl9wwKc29Z0ADPKM5CiNMcwkzCuJ+9lT/z/SbcSh1ptYi9D3apHAVSMeHCQdwOCJ8RVbaSrYGVxqPJvXVvSp6SZmlO03xDZOh8DdY1mUGANRMi8Ds3bwrwxUIwcxFOeSTDavhC8DMD23P94vNkYsf7AbHhgg+57XAgheEqoZRj8FYcmFT5ZqTLAQaMcZNL+H8zwFd1JVPbf6V+5FaPWLZXsB/7kd8OGsMPyoE4WoDujifP7448NOFjBmw45zbmO+N9V4PpvPqswx+FvyOnDIa4hgJuVZoDFt+8WZLrl+L/vhqCE7zK2JXH1zhL17DG0ELkxhenTBTLutBmZyDrbOh7KSx/GwtMoiUq7bcoQdEjxh1re8n0hmFsguqIXuZp1zt3d/OYZbxxGOVxoWY0rIFaM= gob@popper-3-wsl"
    ];
  };
  fileSystems."/video-storage" = {
    device = "/dev/mapper/media-volume";
    fsType = "ext4";
  };

  nixpkgs.config.nvidia.acceptLicense = true;
  nixpkgs.config.allowUnfree = true;

  security.polkit.enable = true;

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.graceful = true;
    efi.canTouchEfiVariables = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  services = {
    homeManagement.enable = true;
    vscode-server.enable = true;
  };

  networking = {
    useDHCP = lib.mkForce false;
    hostName = "ockham";
    domain = "viselaya.org";
    interfaces.eno1.ipv4.addresses = [
      { address = "10.200.10.4"; prefixLength = 24; }
    ];
    vlans = {
      vlan20 = { interface = "eno1"; id = 20; };
    };
    interfaces.vlan20.ipv4.addresses = [
      { address = "10.200.70.2"; prefixLength = 24; }
    ];
    defaultGateway = "10.200.10.1";
    nameservers = [ "10.200.10.1" "1.1.1.1" ];
  };

  system.stateVersion = "22.11";
}
