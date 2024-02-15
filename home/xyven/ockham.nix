{ pkgs, ... }:

{
  imports = [
    ./generic.nix
  ];
  home = {
    packages = with pkgs.unstable; [
      vagrant

      lua-language-server
    ];
  };
  programs.fish = {
    functions = {
      update = "env -C /etc/nixos/ nix flake lock --update-input home-management && rb";
    };
    interactiveShellInit = ''
      eval (ssh-agent -c)
      ssh-add
    '';
  };
}
