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
    ../common/optional/fish.nix
  ];

  users.users.xyven = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9OUNpoctlB+kygCCqcP/YRPDzGcykblU5TKUnfKhY+ blake@gretchen"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqKxEMH57VYdc6hCe25uBkok0KeArgwARqOs1Dw1UBu xyven@festus"
    ];
  };
  fileSystems."/video-storage" = {
    device = "/dev/mapper/media-volume";
    fsType = "ext4";
  };

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
    interfaces.eno1 = {
      ipv4.addresses = [
        { address = "10.200.10.4"; prefixLength = 24; }
        # { address = "10.200.70.2"; prefixLength = 24; }
      ];
    };

    defaultGateway = "10.200.10.1";
    nameservers = [ "10.200.10.1" "1.1.1.1" ];
  };

  system.stateVersion = "22.11";
}
