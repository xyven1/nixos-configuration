{pkgs, ...}: {
  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];
  services.kmscon = {
    enable = true;
    config = {
      font-name = "JetBrainsMono Nerd Font";
      hwaccel = true;
    };
  };
}
