{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./accelerated-video.nix
    # ./biometrics.nix
    ./nvidia.nix # ./nvidia-disable.nix

    ../common/global
    ../common/users/xyven
    ../common/optional/gnome.nix
  ];

  # Setup keyfile
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    initrd.secrets = {
      "/crypto_keyfile.bin" = null;
    };
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
  };
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "festus"; # Define your hostname.
    networkmanager.enable = true;
  };

  services.fwupd.enable = true;

  services.fstrim.enable = true;

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # improve boot time
  systemd.services.NetworkManager-wait-online.enable = false;

  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_HWP_ON_AC = "performance";
      CPU_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      ENERGY_PERF_POLICY_ON_AC = "performance";
    };
  };
  services.power-profiles-daemon.enable = false;

  system.stateVersion = "22.11"; # Did you read the comment?
}
