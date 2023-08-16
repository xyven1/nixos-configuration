{ lib, pkgs, inputs, ... }:

{
  imports = [
    ./generic.nix
  ];
  home = {
    packages = with pkgs; [
      unstable.vagrant

      unstable.lua-language-server
    ];
  };
  programs.fish = {
    functions = {
      rb = "env -C /etc/nixos/ sudo nixos-rebuild switch --flake .#ockham";
      rbh = "env -C /etc/nixos/ home-manager switch --flake .#xyven@ockham";
      update = "env -C /etc/nixos/ nix flake lock --update-input home-management && rb";
    };
    interactiveShellInit = ''
      eval (ssh-agent -c)
      ssh-add
    '';
  };
}
