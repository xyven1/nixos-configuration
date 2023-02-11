{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./user.nix
  ];
  config = {
    nixpkgs.config.allowUnfree = true;
    nix = {
      package = pkgs.unstable.nix;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
  };
}

