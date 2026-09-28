# Reverse proxy for loudrectangle (10.1.0.3), greg's server behind this one.
# The port list mirrors ports.nix in
# https://github.com/ITotallyExist/loudrectangle-nix-config
#
# - HTTPS sites: TLS ends here (Let's Encrypt via HTTP-01), plain HTTP to
#   loudrectangle.
# - Mail and Minecraft are raw TCP, forwarded with the nginx stream module.
#   The router must forward these ports to keppler.
#   Mail gets `proxy_protocol on` so Stalwart sees each client's real IP
#   (needed for spam filtering). Stalwart trusts the PROXY header from
#   10.1.0.2 only, and requires it on these ports.
{...}: let
  upstream = "10.1.0.3";
  proxyTo = port: {
    proxyPass = "http://${upstream}:${toString port}";
    proxyWebsockets = true;
    recommendedProxySettings = true;
  };
in {
  services.nginx.virtualHosts = {
    # Stalwart: web admin, account portal, JMAP, mail client autoconfig, MTA-STS
    "mail.gregmail.net" = {
      serverAliases = [
        "autoconfig.gregmail.net"
        "autodiscover.gregmail.net"
        "mta-sts.gregmail.net"
      ];
      enableACME = true;
      forceSSL = true;
      locations."/" = proxyTo 42002;
    };

    # OpenCloud file storage: large uploads, long-lived sync connections
    "drive.gregsite.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" =
        proxyTo 42003
        // {
          extraConfig = ''
            client_max_body_size 0;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
          '';
        };
    };
  };

  services.nginx.streamConfig = ''
    # gregmail.net: SMTP (MX), submissions, submission, IMAPS
    server { listen 25;  proxy_pass ${upstream}:25;  proxy_protocol on; }
    server { listen 465; proxy_pass ${upstream}:465; proxy_protocol on; }
    server { listen 587; proxy_pass ${upstream}:587; proxy_protocol on; }
    server { listen 993; proxy_pass ${upstream}:993; proxy_protocol on; }

    # GregTech: New Horizons Minecraft server (1.7.10 can't parse proxy_protocol)
    server { listen 25565; proxy_pass ${upstream}:25565; }
  '';

  networking.firewall.allowedTCPPorts = [25 465 587 993 25565];
}
