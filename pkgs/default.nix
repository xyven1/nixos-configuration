{ pkgs }: {
  # example = pkgs.callPackage ./example { };
  tlpui = pkgs.python3Packages.callPackage ./tlpui.nix { };
  wpi-wireless-install = pkgs.callPackage ./wpi-wireless-install { };
}
