{
  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nginx = {
    enable = true;
    # reverse proxy for port 43434
    virtualHosts."localhost" = {
      locations."/".proxyPass = "http://localhost:43434";
    };
  };
}
