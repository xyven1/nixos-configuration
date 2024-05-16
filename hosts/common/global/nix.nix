{lib, ...}: {
  nix = {
    settings = {
      auto-optimise-store = lib.mkDefault true;
      experimental-features = ["nix-command" "flakes" "repl-flake"];
      warn-dirty = false;
      substituters = [
        "https://hyprland.cachix.org"
        "https://xyven1.cachix.org"
      ];
      trusted-public-keys = [
        "xyven1.cachix.org-1:Eb3g2wdg3iE6nWKzC6OK3IXg54OTokehG539mo1wrmQ="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
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
