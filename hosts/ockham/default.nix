{
  inputs,
  lib,
  ...
}: let
  disks = ["/dev/nvme0n1"];
in {
  imports = [
    inputs.vscode-server.nixosModules.default
    ./hardware-configuration.nix
    ./nvidia.nix
    ./ssh.nix
    ./services
    (import ./disko.nix {
      disks = disks;
    })
    ../common/global
    ../common/users/xyven
    ../common/users/gob
  ];

  fileSystems."/video-storage" = {
    device = "/dev/mapper/media-volume";
    fsType = "ext4";
  };

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
      {
        address = "10.200.10.4";
        prefixLength = 24;
      }
    ];
    vlans = {
      vlan20 = {
        interface = "eno1";
        id = 20;
      };
    };
    interfaces.vlan20.ipv4.addresses = [
      {
        address = "10.200.70.2";
        prefixLength = 24;
      }
    ];
    defaultGateway = "10.200.10.1";
    nameservers = ["10.200.10.1" "1.1.1.1"];
  };

  system.stateVersion = "22.11";
}
