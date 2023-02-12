{ pkgs, ... }: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "JetBrains Nerd Font";
      package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
    };
    regular = {
      family = "Fira Sans";
      package = pkgs.fira;
    };
  };
}
