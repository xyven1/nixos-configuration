{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./accelerated-video.nix
    ./biometrics.nix
    ./hardware-configuration.nix
    ./nvidia-disable.nix

    ../common/global
    ../common/users/xyven
    ../common/optional/gnome.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    clearLinuxPatches.enable = false;
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
  environment.systemPackages = [pkgs.sbctl];
  hardware.enableRedistributableFirmware = true;
  # improve boot time
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.docker.wantedBy = lib.mkForce [];
  systemd.sleep.extraConfig = ''
    HibernateMode=platform
  '';

  services.resolved.enable = true;
  networking = {
    hostName = "festus";
    networkmanager.enable = true;
    firewall = rec {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = allowedTCPPortRanges;
    };
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;

  # Services
  services.fwupd.enable = true;
  services.fstrim.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # allow gnome to manage system time
  time.timeZone = null;

  # Power management
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
    };
  };
  services.power-profiles-daemon.enable = false;

  system.stateVersion = "24.05"; # Did you read the comment?
}
