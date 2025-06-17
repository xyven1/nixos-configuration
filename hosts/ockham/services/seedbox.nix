{
  config,
  pkgs,
  lib,
  ...
}: {
  nixpkgs.allowUnfreePackages = ["plexmediaserver" "unrar"];

  users.groups.seedbox = {};
  # allow
  services = {
    plex = {
      enable = true;
      group = "seedbox";
      openFirewall = true;
      package = pkgs.unstable.plex;
    };
    sonarr = {
      enable = true;
      group = "seedbox";
      package = pkgs.unstable.sonarr;
    };
    radarr = {
      enable = true;
      group = "seedbox";
      package = pkgs.unstable.radarr;
    };
    prowlarr = {
      enable = true;
      package = pkgs.unstable.prowlarr;
    };
    unpackerr = {
      enable = true;
      group = "seedbox";
      package = pkgs.unstable.unpackerr;
    };
    transmission = {
      enable = true;
      group = "seedbox";
      package = pkgs.unstable.transmission_4;
      downloadDirPermissions = "770";
    };
    ombi = {
      enable = true;
      group = "seedbox";
      package = pkgs.unstable.ombi;
      openFirewall = true;
    };
    sabnzbd = {
      enable = true;
      group = "seedbox";
      package = pkgs.unstable.sabnzbd;
    };
    vopono = {
      enable = true;
      group = "seedbox";
      protocol = "Wireguard";
      provider = "Mullvad";
      server = "usa-us";
      namespace = "seedbox";
      interface = "wlp0s20f3";
      services = {
        radarr = [7878];
        sonarr = [8989];
        prowlarr = [9696];
        sabnzbd = [8080];
        transmission = [9091];
      };
    };
  };

  # allow services inside netns to access Plex
  networking.firewall.interfaces."${config.services.vopono.namespace}_d".allowedTCPPorts = [32400];
}
