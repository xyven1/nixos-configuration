{pkgs ? import <nixpkgs> {}}: let
  python3Packages = pkgs.python3Packages.override {
    overrides = import ./top-level/python-packages.nix;
  };
  applications = import ./top-level/all-packages.nix {inherit pkgs python3Packages;};
in
  applications
  // {
    inherit python3Packages;
  }
