{
  config,
  lib,
  ...
}: let
  fqdn = "${config.networking.hostName}.${config.networking.domain}";
in {
  networking.firewall.allowedTCPPorts = [80 443];
  sops.secrets.cloudflare = {};
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@xyven.dev";
    certs."${fqdn}" = {
      domain = fqdn;
      extraDomainNames = ["*.${fqdn}"];
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare.path;
      group = "nginx";
    };
  };
  services.nginx = let
    srv = config.services;
  in {
    enable = true;
    appendHttpConfig = ''
      proxy_headers_hash_bucket_size 128;
      geo $internal_traffic {
        default 0;
        10.200.0.0/16 1;
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
        "" = {
          port = srv.home-management.port;
          basic = {
            extraConfig = ''
              proxy_pass_request_headers      on;
              add_header Last-Modified $date_gmt;
              add_header Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
              if_modified_since off;
              expires off;
              etag off;
            '';
          };
        };
        unifi.locations = let
          extraConfig = ssl_no_verify: ''
            proxy_set_header Referer \'\';
            proxy_set_header Origin \'\';
            proxy_buffering off;
            proxy_hide_header Authorization;
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
        monitor = {
          port = srv.grafana.settings.server.http_port;
          basic = {};
        };
        plex = {
          port = 32400;
          public = true;
          basic = {
            extraConfig = ''
              gzip on;
              gzip_vary on;
              gzip_min_length 1000;
              gzip_proxied any;
              gzip_types text/plain text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
              gzip_disable "MSIE [1-6]\.";

              # Forward real ip and host to Plex
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              #When using ngx_http_realip_module change $proxy_add_x_forwarded_for to '$http_x_forwarded_for,$realip_remote_addr'
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Sec-WebSocket-Extensions $http_sec_websocket_extensions;
              proxy_set_header Sec-WebSocket-Key $http_sec_websocket_key;
              proxy_set_header Sec-WebSocket-Version $http_sec_websocket_version;

              # Buffering off send to the client as soon as the data is received from Plex.
              proxy_redirect off;
              proxy_buffering off;
            '';
          };
        };
        jellyfin = {
          port = 8096;
          public = true;
          basic = {
            extraConfig = ''
              proxy_buffering off;
            '';
          };
        };
        jellyseerr = {
          port = srv.jellyseerr.port;
          public = true;
          basic = {};
        };
        tautulli = {
          port = srv.tautulli.port;
          basic = {};
        };
        overseerr = {
          port = srv.overseerr.port;
          public = true;
          basic = {};
        };
        unpackerr = {
          port = 5656;
          basic = {};
        };
        profilarr = {
          port = 6868;
          basic = {};
        };
        radarr = {
          port = srv.radarr.settings.server.port;
          host = "10.200.1.2";
          basic = {};
        };
        sonarr = {
          port = srv.sonarr.settings.server.port;
          host = "10.200.1.2";
          basic = {};
        };
        prowlarr = {
          port = srv.prowlarr.settings.server.port;
          host = "10.200.1.2";
          basic = {};
        };
        flaresolverr = {
          port = srv.flaresolverr.port;
          host = "10.200.1.2";
          basic = {};
        };
        qbittorrent = {
          port = srv.qbittorrent.webuiPort;
          host = "10.200.1.2";
          basic = {};
        };
      };
  };
}
