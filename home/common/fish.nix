{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      n = "nix";
      nd = "nix develop -c $SHELL";
      ns = "nix shell";
      nsn = "nix shell nixpkgs#";
      nb = "nix build";
      nbn = "nix build nixpkgs#";
      nf = "nix flake";

      nr = "nixos-rebuild --flake .";
      nrs = "nixos-rebuild --flake . switch";
      snr = "sudo nixos-rebuild --flake .";
      snrs = "sudo nixos-rebuild --flake . switch";
      hm = "home-manager --flake .";
      hms = "home-manager --flake . switch";

      v = "nvim";
      vi = "nvim";
      vim = "nvim";
    };
    shellAliases = {
      "cd-conf" = "cd /home/xyven/code/nixos-configuration";
    };
    functions = {
      fish_greeting = "";
      rb = "env -C /home/xyven/code/nixos-configuration sudo nixos-rebuild switch --flake .#laptop";
      rbh = "env -C /home/xyven/code/nixos-configuration home-manager switch --flake .#xyven@laptop";
      "nvim-update" = "env -C /home/xyven/code/nixos-configuration nix flake lock --update-input neovim-nightly-overlay --update-input neovim-config && rebuild-home";
      "nvim-update-config" = "env -C /home/xyven/code/nixos-configuration nix flake lock --update-input neovim-config && rebuild-home";
    };
  };
}
