{ pkgs, config, lib, ... }: {
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx =
    let
      domain = "${config.networking.hostName}.${config.networking.domain}";
      e' = "''";
    in
    {
      enable = true;
      # reverse proxy for port 43434
      virtualHosts = lib.mapAttrs
        (name: cfg: {
          forceSSL = true;
          sslCertificate = "/etc/certtest/ockham.crt";
          sslCertificateKey = "/etc/certtest/ockham.key";
        } // cfg)
        {
          ${domain} = {
            locations."/" = {
              proxyPass = "http://127.0.0.1:43434";
              recommendedProxySettings = true;
              proxyWebsockets = true;
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
          "unifi.${domain}" = {
            locations = {
              "/" = {
                proxyPass = "https://127.0.0.1:8443/";
                recommendedProxySettings = true;
                extraConfig = ''
                  proxy_ssl_verify off;
                  proxy_ssl_session_reuse on;
                  proxy_buffering off;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";
                  proxy_hide_header Authorization;
                  proxy_set_header Referer ${e'};
                  proxy_set_header Origin ${e'};
                '';
                priority = 100;
              };
              "/inform" = {
                proxyPass = "https://127.0.0.1:8080/";
                recommendedProxySettings = true;
                extraConfig = ''
                  proxy_ssl_verify off;
                  proxy_ssl_session_reuse on;
                  proxy_buffering off;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";
                  proxy_hide_header Authorization;
                  proxy_set_header Referer ${e'};
                  proxy_set_header Origin ${e'};
                '';
                priority = 100;
              };
              "/wss" = {
                proxyPass = "https://127.0.0.1:8443/";
                recommendedProxySettings = true;
                extraConfig = ''
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";
                  proxy_set_header Referer ${e'};
                  proxy_set_header Origin ${e'};
                  proxy_buffering off;
                  proxy_hide_header Authorization;
                '';
                priority = 100;
              };
            };
          };
          "plex.${domain}" = {
            locations."/" = {
              proxyPass = "http://127.0.0.1:32400/";
              proxyWebsockets = true;
              recommendedProxySettings = true;
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
          "monitor.${domain}" =
            let settings = config.services.grafana.settings; in {
              locations."/" = {
                proxyPass = "http://127.0.0.1:${toString settings.server.http_port}";
                proxyWebsockets = true;
                recommendedProxySettings = true;
              };
            };
        };
    };
}


































