{ pkgs ? import <nixpkgs> { } }: with pkgs; {
  tlpui = python3Packages.callPackage ./tlpui.nix { };
  sioyek = qt6.callPackage ./sioyek.nix { };
  scenebuilder19 = callPackage ./scenebuilder.nix { };
}
