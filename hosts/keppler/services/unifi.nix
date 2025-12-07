{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.secrets.cloudflare = {};
  custom.nginx = {
    enable = true;
    fqdn = "${config.networking.hostName}.adequately.run";
    localSubnet = "10.1.0.0/16";
    cloudflareCert = {
      email = "acme@xyven.dev";
      wildcard = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
    virtualHosts = {
      unifi.locations."/" = {
        host = "10.73.0.2";
        port = 8443;
        proxyHttps = true;
      };
      portal.locations."/" = {
        host = "10.73.0.2";
        port = 443;
        proxyHttps = true;
      };
    };
  };

  nixpkgs.allowUnfreePackages = [
    "unifi-controller"
    "mongodb"
  ];
  services.unifi = {
    enable = true;
    openFirewall = true;
  };
}
