# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./disko.nix
      ./biometrics.nix
      ./nvidia.nix

      ../common/global
      ../common/users/xyven
      ../common/optional/gnome.nix
      ../common/optional/fish.nix
    ];

  # Setup keyfile
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    initrd.secrets = {
      "/crypto_keyfile.bin" = null;
    };
  };

  networking = {
    hostName = "festus"; # Define your hostname.
    networkmanager.enable = true;
  };

  systemConfig.home-manager = {
    enable = true;
    hostName = "laptop";
  };

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

  # powerManagement.powertop.enable = true;
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

  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "xyven";
  };

  system.stateVersion = "22.11"; # Did you read the comment?
}
