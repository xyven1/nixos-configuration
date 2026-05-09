{pkgs ? import <nixpkgs> {}}: let
  pythonExtension = self: super:
    pkgs.lib.packagesFromDirectoryRecursive {
      callPackage = self.callPackage;
      directory = ./python-modules;
    };

  pkgs' = pkgs.extend (self: super: {
    pythonPackagesExtensions =
      super.pythonPackagesExtensions
      ++ [pythonExtension];
  });
in (pkgs.lib.packagesFromDirectoryRecursive {
  callPackage = pkgs'.callPackage;
  directory = ./applications;
})
