{
  inputs,
  pkgs,
  ...
}: {
  disabledModules = ["services/networking/unifi.nix"];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/unifi.nix"
  ];
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unstable.unifi7;
    openFirewall = true;
  };
}
