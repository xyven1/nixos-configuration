{lib, ...}: {
  imports = [
    ../shared/nixpkgs.nix
  ];
  # enable overlays defined in overlay/default.nix by default
  nixpkgs.myOverlays.enable = true;
  # this fixes an evaluation issue caused by HM defaulting `nixpkgs.config` to null
  nixpkgs.config = lib.mkDefault {
    allowUnfree = false;
  };
}
