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
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "23.05";
}
