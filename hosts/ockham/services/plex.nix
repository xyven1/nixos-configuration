{pkgs, ...}: {
  nixpkgs.allowUnfreePackages = [
    "plexmediaserver"
  ];

  services.plex = {
    enable = true;
    openFirewall = true;
    package = pkgs.unstable.plex;
  };
  systemd.services.plex.serviceConfig = {
    # Hardening
    NoNewPrivileges = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectSystem = true;
    ProtectHome = true;
    ProtectControlGroups = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET5" "AF_NETLINK"];
    # RestrictNamespaces = true; # This could be made to work if the namespaces needed were known
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    MemoryDenyWriteExecute = true;
    LockPersonality = true;
  };
}
