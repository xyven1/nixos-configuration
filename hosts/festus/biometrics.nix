{pkgs, ...}: let
  tod-pkg = "libfprint-2-tod1-goodix";
in {
  nixpkgs.allowUnfreePackages = [
    tod-pkg
  ];
  disabledModules = ["security/pam.nix"];
  imports = [./pam.nix];

  security.pam.serviceDefaults.fprintAuth = false;

  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.${tod-pkg};
    };
  };
}
