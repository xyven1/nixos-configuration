{
  config,
  lib,
  ...
}: let
  fqdn = "${config.networking.hostName}.adequately.run";
in {
  networking.firewall.allowedTCPPorts = [80 443];
  sops.secrets.cloudflare = {};
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@xyven.dev";
    defaults.dnsResolver = "1.1.1.1:53";
    certs."${fqdn}" = {
      domain = fqdn;
      extraDomainNames = ["*.${fqdn}"];
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare.path;
      group = "nginx";
    };
  };
  services.nginx = {
    enable = true;
    appendHttpConfig = ''
      proxy_headers_hash_bucket_size 128;
      geo $internal_traffic {
        default 0;
        10.1.0.0/16 1;
      }
    '';
    virtualHosts =
      lib.mapAttrs'
      (
        subdomain: cfg: {
          name =
            if subdomain == "_"
            then "_"
            else if subdomain == ""
            then fqdn
            else "${subdomain}.${fqdn}";
          value = let
            public = cfg ? public && lib.isBool cfg.public && cfg.public == true;
          in
            {
              forceSSL = true;
              useACMEHost = "${fqdn}";
              extraConfig = lib.mkIf (!public) ''
                if ($internal_traffic = 0) {
                  return 444;
                }
              '';
            }
            // (
              if cfg ? basic && lib.isAttrs cfg.basic
              then {
                locations."/" =
                  {
                    proxyPass = "http://${cfg.host or "127.0.0.1"}:${toString (cfg.port or 80)}";
                    proxyWebsockets = true;
                    recommendedProxySettings = true;
                  }
                  // cfg.basic;
              }
              else cfg
            );
        }
      )
      {
        _ = {
          default = true;
          extraConfig = ''
            deny all;
          '';
        };
        unifi.locations = let
          extraConfig = ssl_no_verify: ''
            proxy_set_header Referer ''';
            proxy_set_header Origin ''';
            proxy_buffering off;
            proxy_hide_header Authorization;
            client_max_body_size 10m;
            ${
              if ssl_no_verify
              then ''
                proxy_ssl_verify off;
                proxy_ssl_session_reuse on;
              ''
              else ""
            }
          '';
        in {
          "/" = {
            proxyPass = "https://127.0.0.1:8443/";
            recommendedProxySettings = true;
            proxyWebsockets = true;
            extraConfig = extraConfig true;
          };
          "/inform" = {
            proxyPass = "https://127.0.0.1:8080/";
            recommendedProxySettings = true;
            proxyWebsockets = true;
            extraConfig = extraConfig true;
          };
          "/wss" = {
            proxyPass = "https://127.0.0.1:8443/";
            recommendedProxySettings = true;
            proxyWebsockets = true;
            extraConfig = extraConfig false;
          };
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
