{pkgs, ...}: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "JetBrains Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
    regular = {
      family = "Fira Sans";
      package = pkgs.fira;
    };
  };
}
