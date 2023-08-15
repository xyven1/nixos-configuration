{ pkgs, ... }: {
  services.plex = {
    enable = true;
    openFirewall = true;
    package = pkgs.unstable.plex;
  };
}
