{ pkgs, ... }:

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
    interactiveShellInit = ''
      eval (ssh-agent -c)
      ssh-add
    '';
  };
}
