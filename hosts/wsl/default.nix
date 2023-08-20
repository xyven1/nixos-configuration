{ inputs, pkgs, ... }: {
  imports = [
    ../common/global
    ../common/users/xyven
    inputs.nixos-wsl.nixosModules.default
  ];
  wsl = {
    enable = true;
    defaultUser = "xyven";
    startMenuLaunchers = true;
    nativeSystemd = true;
  };
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "23.05";
}
