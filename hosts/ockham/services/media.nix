{
  config,
  inputs,
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
    image = "santiagosayshey/profilarr:latest";
    pull = "newer";
    ports = ["127.0.0.1:6868:6868"];
    volumes = ["/var/lib/profilarr:/config"];
    environment = {
      TZ = "EST";
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
      package = inputs.nixpkgs-overseer.legacyPackages.${pkgs.system}.overseerr;
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
      server = "usa-us";
      namespace = "media";
      interface = "eno1";
      services = {
        radarr = [];
        sonarr = [];
        prowlarr = [];
        flaresolverr = [];
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
    };
  };

  # allow services inside netns to access Plex
  networking.firewall.interfaces."${config.services.vopono.namespace}_d".allowedTCPPorts = [32400];
}
