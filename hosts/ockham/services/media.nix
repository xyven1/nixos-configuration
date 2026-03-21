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

  # allow services inside netns to access Plex
  networking.firewall.interfaces."${config.services.vopono.namespace}_d".allowedTCPPorts = [32400];
}
