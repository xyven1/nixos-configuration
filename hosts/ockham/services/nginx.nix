{config, ...}: {
  sops.secrets.cloudflare = {};
  custom.nginx = {
    enable = true;
    fqdn = "${config.networking.hostName}.${config.networking.domain}";
    localSubnet = "10.200.0.0/16";
    cloudflareCert = {
      email = "acme@xyven.dev";
      wildcard = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };
}
