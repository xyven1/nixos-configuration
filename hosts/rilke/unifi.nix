{pkgs, ...}: {
  nixpkgs.allowUnfreePackages = [
    "unifi-controller"
    "mongodb"
  ];
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unstable.unifi8;
    mongodbPackage = pkgs.mongodb-6_0;
    openFirewall = true;
  };
}
