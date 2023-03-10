{ pkgs, ... }:
{
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi;
    jrePackage = pkgs.jdk11;
    openFirewall = true;
  };
}
