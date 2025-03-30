{
  nixpkgs = import ./nixpkgs.nix;
  scripts = import ./scripts.nix;
  home-dir = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home.homeDirectory = lib.mkIf pkgs.stdenv.isLinux (lib.mkDefault "/home/${config.home.username}");
  };
}
