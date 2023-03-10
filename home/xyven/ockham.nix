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
      fish-ssh-agent

      unstable.lua-language-server
    ];
  };
  programs.fish = {
    functions = {
      rb = "env -C /etc/nixos/ sudo nixos-rebuild switch --flake .#ockham";
      rbh = "env -C /etc/nixos/ home-manager switch --flake .#xyven@ockham";
      "nvim-update" = "env -C /etc/nixos/ nix flake lock --update-input neovim-nightly-overlay --update-input neovim-config && rebuild-home";
      "nvim-update-config" = "env -C /etc/nixos/ nix flake lock --update-input neovim-config && rebuild-home";
    };
    plugins = [
      { name = "fish-ssh-agent"; src = pkgs.fish-ssh-agent; }
    ];
  };
}
