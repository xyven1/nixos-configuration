{ lib, pkgs, inputs, ... }:

{
  imports = [
    ./generic.nix
  ];
  home = {
    packages = with pkgs; [
      wslu
      wsl-open

      unstable.lua-language-server
    ];
  };
  programs.fish = {
    functions = {
      rb = "env -C /etc/nixos/ sudo nixos-rebuild switch --flake .#wsl";
      rbh = "env -C /etc/nixos/ home-manager switch --flake .#xyven@wsl";
    };
    interactiveShellInit = ''
      eval (ssh-agent -c)
      ssh-add
    '';
  };
}
