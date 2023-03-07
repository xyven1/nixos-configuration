{ pkgs, inputs, ... }:

{
  imports = [
    ./generic.nix
  ];
  home = {
    packages = with pkgs; [
      fzf
      gitui
      ripgrep

      unstable.lua-language-server
    ];
  };
}
