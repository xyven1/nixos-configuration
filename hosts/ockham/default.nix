{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../common/global
    ../common/users/xyven
  ];

  networking = {
    hostName = "ockham";
    networkmanager.enable = true;
  };

  system.stateVersion = "22.11";
}
