{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./user.nix
  ];
  config = {
    nixpkgs.config.allowUnfree = true;
    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
  };
}

