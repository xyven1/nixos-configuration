{ pkgs, ... }: {
  imports = [
    ../common/global
    ../common/users/xyven
  ];
  wsl = {
    enable = true;
    defaultUser = "xyven";
    startMenuLaunchers = true;
    nativeSystemd = true;
  };
  system.stateVersion = "23.05";
}
