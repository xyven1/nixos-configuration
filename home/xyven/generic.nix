{ outputs, inputs, lib, pkgs, ... }:

{
  imports = [
    ../common/neovim.nix
    ../common/fish.nix
    ../common/starship.nix
    ../common/direnv.nix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
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
    git = {
      enable = true;
      userName = "xyven1";
      userEmail = "git@xyven.dev";
    };
    eza = {
      enable = true;
      enableAliases = true;
      icons = true;
      git = true;
    };
    fzf.enable = true;
    gitui.enable = true;
  };

  home = {
    username = "xyven";
    homeDirectory = "/home/xyven";
    sessionVariables = {
      NIX_AUTO_RUN = "1";
    };
    packages = with pkgs; [
      ripgrep
    ];
  };


  home.stateVersion = "22.11";
}

