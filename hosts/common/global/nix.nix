{
  lib,
  pkgs,
  inputs,
  ...
}: {
  nix = {
    package = pkgs.unstable.lix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
      substituters = [
        "https://xyven1.cachix.org"
        "https://nix-community.cachix.org"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "xyven1.cachix.org-1:Eb3g2wdg3iE6nWKzC6OK3IXg54OTokehG539mo1wrmQ="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
    optimise = {
      automatic = true;
      dates = ["weekly 3:45"];
      persistent = true;
    };
    gc = {
      automatic = true;
      dates = ["weekly 3:15"];
      persistent = true;
    };
    registry = lib.pipe inputs [
      (lib.filterAttrs (name: value: value ? outputs))
      (lib.mapAttrs (name: v: {flake = v;}))
    ];
    nixPath = ["/etc/nix/inputs"];
  };
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/inputs/${name}";
      value = {source = value.outPath;};
    })
    inputs;
}
