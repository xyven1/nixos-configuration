{lib, ...}: {
  nix = {
    settings = {
      auto-optimise-store = lib.mkDefault true;
      experimental-features = ["nix-command" "flakes" "repl-flake"];
      warn-dirty = false;
      substituters = [
        "https://xyven1.cachix.org"
      ];
      trusted-public-keys = [
        "xyven1.cachix.org-1:Eb3g2wdg3iE6nWKzC6OK3IXg54OTokehG539mo1wrmQ="
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
