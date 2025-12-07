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
    virtualHosts = let
      srv = config.services;
    in {
      "".locations."/" = {
        port = srv.home-management.port;
        overrides = {
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
      unifi.locations."/" = {
        port = 8443;
        proxyHttps = true;
      };
      monitor.locations."/".port = srv.grafana.settings.server.http_port;
      plex = {
        public = true;
        locations."/" = {
          port = 32400;
          overrides = {
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
      };
      jellyfin = {
        public = true;
        locations."/" = {
          port = 8096;
          overrides = {
            extraConfig = ''
              proxy_buffering off;
            '';
          };
        };
      };
      jellyseerr = {
        public = true;
        locations."/" = {
          port = srv.jellyseerr.port;
        };
      };
      overseerr = {
        public = true;
        locations."/" = {
          port = srv.overseerr.port;
        };
      };
      tautulli.locations."/".port = srv.tautulli.port;
      unpackerr.locations."/" .port = 5656;
      profilarr.locations."/".port = 6868;
      radarr.locations."/".port = srv.radarr.settings.server.port;
      sonarr.locations."/".port = srv.sonarr.settings.server.port;
      prowlarr.locations."/".port = srv.prowlarr.settings.server.port;
      flaresolverr.locations."/".port = srv.flaresolverr.port;
      qbittorrent.locations."/" = {
        port = srv.qbittorrent.webuiPort;
        host = "10.200.1.2";
      };
    };
  };
}
