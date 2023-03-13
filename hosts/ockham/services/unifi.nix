{ pkgs, ... }:
{
  # this was needed, even with openFirewall = true, to get the controller to get through the backup restore and intial login
  # networking.firewall.allowedTCPPorts = [ 8080 8443 ];
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unstable.unifi;
    jrePackage = pkgs.jdk11;
    openFirewall = true;
  };
}
