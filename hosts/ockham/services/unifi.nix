{pkgs, ...}: {
  nixpkgs.allowUnfreePackages = [
    "unifi-controller"
    "mongodb"
  ];
  nixpkgs.overlays = [
    (prev: final: {
      mongodb-5_0 = final.mongodb-5_0.overrideAttrs (old: {
        src = final.fetchFromGitHub {
          owner = "mongodb";
          repo = "mongo";
          rev = "r5.0.24";
          hash = "sha256-SZ62OJD6L3aP6LsTswpuXaayqYbOaSQTgEmV89Si7Xc=";
        };

        sconsFlags = old.sconsFlags ++ ["MONGO_VERSION=5.0.24"];
      });
    })
  ];
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unstable.unifi8;
    openFirewall = true;
  };
}
