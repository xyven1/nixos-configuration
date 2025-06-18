{
  config,
  pkgs,
  ...
}: {
  nixpkgs.allowUnfreePackages = ["plexmediaserver" "unrar"];

  users.groups.media = {};
  # allow
  services = {
    plex = {
      enable = true;
      group = "media";
      openFirewall = true;
      package = pkgs.unstable.plex;
    };
    sonarr = {
      enable = true;
      group = "media";
      package = pkgs.unstable.sonarr;
    };
    radarr = {
      enable = true;
      group = "media";
      package = pkgs.unstable.radarr;
    };
    prowlarr = {
      enable = true;
      package = pkgs.unstable.prowlarr;
    };
    unpackerr = {
      enable = true;
      group = "media";
      package = pkgs.unstable.unpackerr;
    };
    ombi = {
      enable = true;
      group = "media";
      package = pkgs.unstable.ombi;
      openFirewall = true;
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
  };

  # allow services inside netns to access Plex
  networking.firewall.interfaces."${config.services.vopono.namespace}_d".allowedTCPPorts = [32400];
}
