{ pkgs, ... }: {
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;
    # reverse proxy for port 43434
    virtualHosts."ockham.viselaya.org" = {
      locations."/" = {
        proxyPass = "http://localhost:43434";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_pass_request_headers      on;
        '';
      };
      forceSSL = true;
      sslCertificate = "/etc/certtest/ockham.crt";
      sslCertificateKey = "/etc/certtest/ockham.key";
    };
  };
  # simple web server which will periodically pull certificates from
  # router, and respond to updates
  # systemd.services.ockham = {
  #   enable = true;
  #   wantedBy = [ "multi-user.target" ];
  #   wants = [ "network.target" ];
  #   after = [ "network.target" ];
  #   serviceConfig = {
  #     User = "nginx";
  #     ExecStart = "${pkgs.python3}/bin/python3 -m http.server 43434";
  #     WorkingDirectory = "/etc/certtest";
  #     Restart = "always";
  #     RestartSec = "10";
  #   };
  # };
}
