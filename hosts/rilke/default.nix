{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./minecraft.nix

    ../common/global
    ../common/users/xyven
    ../common/optional/gnome.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    loader.efi.canTouchEfiVariables = true;
  };

  hardware.enableRedistributableFirmware = true;

  time.timeZone = "America/Denver";
  services.tailscale.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
      };
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users = {
    xyven.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqKxEMH57VYdc6hCe25uBkok0KeArgwARqOs1Dw1UBu xyven@festus"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEq5E8HRvArWWc5F9+qI6AuU9Kh1CoJ8/lZ+jErnQAOC xyven@BLAKE-XPS17"
    ];
  };

  services.udev.packages = [pkgs.headsetcontrol];

  # Services
  services.fwupd.enable = true;
  services.fstrim.enable = true;
  services.resolved.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  services.power-profiles-daemon.enable = false;
  services.thermald.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?
}
