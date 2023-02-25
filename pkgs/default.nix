{ pkgs }: with pkgs; {
  # example = pkgs.callPackage ./example { };
  tlpui = python3Packages.callPackage ./tlpui.nix { };
  spotify-player = callPackage ./spotify-player.nix { };
  wpi-wireless-install = callPackage ./wpi-wireless-install { };
}
