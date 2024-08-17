{lib, ...}: {
  nix = {
    settings = {
      auto-optimise-store = lib.mkDefault true;
      experimental-features = ["nix-command" "flakes" "repl-flake"];
      warn-dirty = false;
      substituters = [
        "https://xyven1.cachix.org"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "xyven1.cachix.org-1:Eb3g2wdg3iE6nWKzC6OK3IXg54OTokehG539mo1wrmQ="
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
