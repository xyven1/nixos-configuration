{...}: {
  nixpkgs.allowUnfreePackages = [
    "unifi-controller"
    "mongodb"
  ];
  services.unifi = {
    enable = true;
    openFirewall = true;
  };
  # allow login
  networking.firewall.allowedTCPPorts = [8443];
}
