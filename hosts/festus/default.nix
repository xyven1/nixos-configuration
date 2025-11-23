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
    loader.efi.efiSysMountPoint = "/boot/efi";
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    # For hibernation
    resumeDevice = "/dev/disk/by-label/NixOS";
    kernelParams = [
      "resume_offset=11436032"
      "quiet"
      "udev.log_level=3"
    ];
    plymouth.enable = true;
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
  services.logind.settings.Login = {
    HandlePowerKey = "hibernate";
    HandlePowerKeyLongPress = "poweroff";
    HandleLidSwitch = "suspend-then-hibernate";
  };
  systemd.sleep.extraConfig = ''
    SuspendState=mem
    MemorySleepMode=s2idle
    HibernateMode=platform
    HibernateOnACPower=no
    HibernateDelaySec=30m
  '';

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
  environment.variables = {
    GSK_RENDERER = "ngl";
  };
  hardware.enableRedistributableFirmware = true;
  # improve boot time
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.docker.wantedBy = lib.mkForce [];

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
    plugins = [pkgs.unstable.evolution-ews];
  };

  system.stateVersion = "24.05";
}
