{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.chaotic.nixosModules.default
    ./accelerated-video.nix
    ./biometrics.nix
    ./hardware-configuration.nix
    ./nvidia.nix

    ../common/global
    ../common/users/xyven
    ../common/optional/gnome.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_cachyos;
    # Setup keyfile
    initrd.secrets."/crypto_keyfile.bin" = null;
    loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    # For hibernation
    resumeDevice = "/dev/dm-0";
    kernelParams = ["resume_offset=113446912"];
  };
  environment.systemPackages = with pkgs; [sbctl];
  security.wrappers = {
    nethogs = {
      source = lib.getExe pkgs.nethogs;
      capabilities = "cap_net_admin=ep cap_net_raw=ep";
      owner = "root";
      group = "root";
      permissions = "u+rx,g+x,o+x";
    };
  };
  hardware.enableRedistributableFirmware = true;
  # improve boot time
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.docker.wantedBy = lib.mkForce [];
  systemd.sleep.extraConfig = ''
    HibernateMode=platform
  '';

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;

  # Enable split tunnel dns
  services.resolved.enable = true;

  # Enable firmware updates
  services.fwupd.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # Power management
  services.thermald.enable = true;

  # Enable evolution data server with ews support
  programs.evolution = {
    enable = true;
    plugins = [pkgs.evolution-ews];
  };

  system.stateVersion = "24.05";
}
