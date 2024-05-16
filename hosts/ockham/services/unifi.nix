{pkgs, ...}: {
  nixpkgs.allowUnfreePackages = [
    "unifi-controller"
    "mongodb"
  ];
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unstable.unifi8;
    openFirewall = true;
  };
}
