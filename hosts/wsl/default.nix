{ inputs, pkgs, ... }: {
  imports = [
    ../common/global
    ../common/users/xyven
  ];
  import = [
    inputs.nixos-wsl.nixosModules.wsl
  ];
  wsl = {
    enable = true;
    defaultUser = "xyven";
    startMenuLaunchers = true;
    nativeSystemd = true;
  };
  system.stateVersion = "23.05";
}
