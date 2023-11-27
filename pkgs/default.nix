{ pkgs ? import <nixpkgs> { } }: with pkgs; {
  tlpui = python3Packages.callPackage ./tlpui.nix { };
  wpi-wireless-install = callPackage ./wpi-wireless-install { };
  scenebuilder19 = callPackage ./scenebuilder.nix { };
}
