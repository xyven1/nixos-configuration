# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./disko.nix
      ./biometrics.nix

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
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;

  # enable propprietary nvidia drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  system.stateVersion = "22.11"; # Did you read the comment?
}
