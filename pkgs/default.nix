{pkgs ? import <nixpkgs> {}}: let
  scope = pkgs.lib.makeScope pkgs.lib.callPackageWith (self: {
    python3Packages = pkgs.python3Packages.override {
      overrides = import ./top-level/python-packages.nix;
    };
  });
  applications = import ./top-level/all-packages.nix scope {};
  python3Packages = import ./top-level/python-packages.nix pkgs.python3Packages {};
in
  applications
  // {
    inherit python3Packages;
  }
