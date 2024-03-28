{pkgs, ...}: {
  imports = [
    ../common/global
    ../common/users/xyven
  ];
  nixpkgs.myOverlays.enable = true;
  fileSystems."/".label = "x";
  environment.systemPackages = [
    pkgs.hello
    pkgs.unstable.hello
    pkgs.rust-bin.nightly.latest.default
    pkgs.neovim
  ];
  boot.loader.grub.enable = false;
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "23.11";
}
