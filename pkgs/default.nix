{pkgs ? import <nixpkgs> {}}: let
  python3Packages = pkgs.python3Packages.override {
    overrides = import ./python-packages.nix;
  };
in {
  tlpui = pkgs.python3Packages.callPackage ./tlpui.nix {};
  sioyek = pkgs.qt6.callPackage ./sioyek.nix {};
  scenebuilder19 = pkgs.callPackage ./scenebuilder.nix {};
  neovide-nightly = pkgs.callPackage ./neovide {};
  droncan-gui-tool = python3Packages.callPackage ./dronecan-gui-tool.nix {};

  wezterm-nightly = pkgs.darwin.apple_sdk_11_0.callPackage ./wezterm {
    inherit (pkgs.darwin.apple_sdk_11_0.frameworks) Cocoa CoreGraphics Foundation UserNotifications System;
  };
  idea-ultimate-latest = pkgs.jetbrains.idea-ultimate.overrideAttrs (_: {
    version = "2022.3";
    src = pkgs.fetchurl {
      url = "https://download-cdn.jetbrains.com/idea/ideaIU-2022.3.3.tar.gz";
      sha256 = "sha256-wwK9hLSKVu8bDwM+jpOg2lWQ+ASC6uFy22Ew2gNTFKY=";
    };
  });
}
