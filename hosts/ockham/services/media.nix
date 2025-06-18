{
  config,
  pkgs,
  lib,
  ...
}: {
  nixpkgs.allowUnfreePackages = ["plexmediaserver" "unrar"];

  sops.secrets =
    lib.genAttrs ["unpackerr/radarr_api_key" "unpackerr/sonarr_api_key"]
    (name: {
      owner = config.users.users.unpackerr.name;
      group = config.users.users.unpackerr.group;
    });
  users.groups.media = {};
  # allow
  services = {
    plex = {
      enable = true;
      group = "media";
      openFirewall = true;
      package = pkgs.unstable.plex;
    };
    tautulli = {
      enable = true;
      group = "media";
      package = pkgs.unstable.tautulli;
    };
    ombi = {
      enable = true;
      group = "media";
      package = pkgs.unstable.ombi;
      openFirewall = true;
    };
    unpackerr = {
      enable = true;
      group = "media";
      package = pkgs.unstable.unpackerr;
      settings = let
        downloads = "${config.services.qbittorrent.dataDir}/qBittorrent/downloads";
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
      port = 8081;
    };
  };

  # allow services inside netns to access Plex
  networking.firewall.interfaces."${config.services.vopono.namespace}_d".allowedTCPPorts = [32400];
}
