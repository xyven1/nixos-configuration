{
  lib,
  pkgs,
  ...
}: {
  nix = {
    package = pkgs.unstable.lix;
    settings = {
      auto-optimise-store = lib.mkDefault true;
      experimental-features = ["nix-command" "flakes" "repl-flake"];
      warn-dirty = false;
      substituters = [
        "https://xyven1.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "xyven1.cachix.org-1:Eb3g2wdg3iE6nWKzC6OK3IXg54OTokehG539mo1wrmQ="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
    };
    generateNixPathFromInputs = true;
    generateRegistryFromInputs = true;
    linkInputs = true;
  };
}
