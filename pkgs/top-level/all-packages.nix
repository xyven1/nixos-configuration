{
  pkgs,
  python3Packages,
}:
with pkgs; {
  droncan-gui-tool = python3Packages.callPackage ../applications/dronecan-gui-tool {};

  neovide-nightly = callPackage ../applications/neovide {};

  scenebuilder19 = callPackage ../applications/scenebuilder {};

  sioyek = qt6.callPackage ../applications/sioyek {};

  tlpui = python3Packages.callPackage ../applications/tlpui {};

  wezterm-nightly = darwin.apple_sdk_11_0.callPackage ../applications/wezterm {
    inherit (pkgs.darwin.apple_sdk_11_0.frameworks) Cocoa CoreGraphics Foundation UserNotifications System;
  };
}
