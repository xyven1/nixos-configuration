{pkgs ? import <nixpkgs> {}}:
import ./top-level/all-packages.nix (
  pkgs.lib.makeScope pkgs.lib.callPackageWith (self:
    pkgs
    // {
      python3Packages = pkgs.python3Packages.override {
        overrides = import ./top-level/python-packages.nix;
      };
    })
) {}
