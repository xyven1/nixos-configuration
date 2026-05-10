{
  config,
  lib,
  pkgs,
  ...
}: {
  nixpkgs.allowUnfreePackages = ["plexmediaserver"];

  sops.secrets =
    lib.genAttrs ["unpackerr/radarr_api_key" "unpackerr/sonarr_api_key"]
    (name: {
      owner = config.users.users.unpackerr.name;
      group = config.users.users.unpackerr.group;
    });
  users.groups.media = {};
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.containers.profilarr = {
    image = "santiagosayshey/profilarr:beta";
    pull = "newer";
    networks = ["host"];
    volumes = ["/var/lib/profilarr:/config"];
    environment = {
      TZ = "America/New_York";
    };
  };
  systemd.services."${config.virtualisation.oci-containers.backend}-profilarr".serviceConfig = {
    StateDirectory = "profilarr";
  };
  services = {
    plex = {
      enable = true;
      group = "media";
      openFirewall = true;
      package = pkgs.unstable.plex;
    };
    jellyfin = {
      enable = true;
      group = "media";
      package = pkgs.unstable.jellyfin;
    };
    jellyseerr = {
      enable = true;
      port = 5056;
      package = pkgs.unstable.jellyseerr;
    };
    tautulli = {
      enable = true;
      group = "media";
      package = pkgs.unstable.tautulli;
    };
    overseerr = {
      enable = true;
      package = pkgs.unstable.overseerr;
    };
    unpackerr = {
      enable = true;
      group = "media";
      package = pkgs.unstable.unpackerr;
      settings = let
        downloads = "${config.services.qbittorrent.profileDir}/qBittorrent/downloads";
      in {
        radarr = [
          {
            url = "http://10.200.1.2:7878";
            api_key = "filepath:${config.sops.secrets."unpackerr/radarr_api_key".path}";
            paths = [downloads];
          }
        ];
        sonarr = [
          {
            url = "http://10.200.1.2:8989";
            api_key = "filepath:${config.sops.secrets."unpackerr/sonarr_api_key".path}";
            paths = [downloads];
          }
        ];
        webserver = {
          metrics = true;
        };
      };
    };
    vopono = {
      enable = true;
      group = "media";
      package = pkgs.unstable.vopono;
      protocol = "Wireguard";
      provider = "Mullvad";
      server = "usa-usbos";
      namespace = "media";
      interface = "eno1";
      services = {
        qbittorrent = [];
      };
    };
    radarr = {
      enable = true;
      group = "media";
      package = pkgs.unstable.radarr;
    };
    sonarr = {
      enable = true;
      group = "media";
      package = pkgs.unstable.sonarr;
    };
    prowlarr = {
      enable = true;
      package = pkgs.unstable.prowlarr;
    };
    flaresolverr = {
      enable = true;
      package = pkgs.unstable.flaresolverr;
    };
    qbittorrent = {
      enable = true;
      group = "media";
      package = pkgs.unstable.qbittorrent-nox;
      webuiPort = 8081;
      serverConfig = {
        AutoRun = {
          enabled = true;
          program = ''${lib.getExe (pkgs.writeShellScriptBin "qbittorrent-chmod" ''chmod -R u=rwX,g=rwX,o=rX "$1" '')} \"%F\"'';
        };

        BitTorrent = {
          MergeTrackersEnabled = true;

          Session = {
            AddTorrentStopped = false;
            AddTrackersFromURLEnabled = true;
            AdditionalTrackersURL = "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt";
            DefaultSavePath = "/video-storage/downloads";
            MaxActiveDownloads = 20;
            MaxActiveTorrents = 40;
            MaxActiveUploads = 20;
            Preallocation = true;
            QueueingSystemEnabled = false;
          };
        };

        Preferences = {
          WebUI = {
            AlternativeUIEnabled = true;
            RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
            Port = 8081;
            Username = "xyven";
            Password_PBKDF2 = "@ByteArray(36ysjPMG/jS5//dD+J5HJA==:V1I+ijL67NjXFDjCBYondouop+FSoNqzuPHlX6zikfDeMtBtgcAWLJL6H7hPTIUiLUd/nf/FBqrZnOEEaLuxiw==)";
          };
        };
      };
    };
  };

  custom.nginx = {
    virtualHosts = let
      srv = config.services;
    in {
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

  # allow services inside netns to access Plex
  networking.firewall.interfaces."${config.services.vopono.namespace}_d".allowedTCPPorts = [32400];
}
