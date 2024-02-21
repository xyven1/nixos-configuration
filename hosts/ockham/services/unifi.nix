{
  inputs,
  pkgs,
  ...
}: {
  disabledModules = ["services/networking/unifi.nix"];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/unifi.nix"
  ];
  nixpkgs.allowUnfreePackages = [
    "unifi-controller"
    "mongodb"
  ];
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unstable.unifi7;
    openFirewall = true;
  };
}
