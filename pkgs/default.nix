{pkgs ? import <nixpkgs> {}}:
with pkgs; {
  tlpui = python3Packages.callPackage ./tlpui.nix {};
  sioyek = qt6.callPackage ./sioyek.nix {};
  scenebuilder19 = callPackage ./scenebuilder.nix {};
  neovide-nightly = callPackage ./neovide {};
  idea-ultimate-latest = pkgs.jetbrains.idea-ultimate.overrideAttrs (_: {
    version = "2022.3";
    src = pkgs.fetchurl {
      url = "https://download-cdn.jetbrains.com/idea/ideaIU-2022.3.3.tar.gz";
      sha256 = "sha256-wwK9hLSKVu8bDwM+jpOg2lWQ+ASC6uFy22Ew2gNTFKY=";
    };
  });
}
