{pkgs ? import <nixpkgs> {}}:
with pkgs; {
  tlpui = python3Packages.callPackage ./tlpui.nix {};
  sioyek = qt6.callPackage ./sioyek.nix {};
  scenebuilder19 = callPackage ./scenebuilder.nix {};
  neovide-nightly = callPackage ./neovide {};
  droncan-gui-tool = python3Packages.callPackage ./dronecan-gui-tool.nix {};

  wezterm-nightly = darwin.apple_sdk_11_0.callPackage ./wezterm {
    inherit (darwin.apple_sdk_11_0.frameworks) Cocoa CoreGraphics Foundation UserNotifications System;
  };
  idea-ultimate-latest = pkgs.jetbrains.idea-ultimate.overrideAttrs (_: {
    version = "2022.3";
    src = pkgs.fetchurl {
      url = "https://download-cdn.jetbrains.com/idea/ideaIU-2022.3.3.tar.gz";
      sha256 = "sha256-wwK9hLSKVu8bDwM+jpOg2lWQ+ASC6uFy22Ew2gNTFKY=";
    };
  });
}
