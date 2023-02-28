{ outputs, inputs, lib, pkgs, ... }:

{
  imports = [
    ../common/neovim.nix
    ../common/font.nix
    ../common/wezterm
    ../common/fish.nix
    ../common/starship.nix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home = {
    username = "xyven";
    homeDirectory = "/home/xyven";
  };

  home.stateVersion = "22.11";
}

