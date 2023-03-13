{ pkgs, ... }:
{
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
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
      nu = "nix flake lock --update-input";

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
    functions = {
      fish_greeting = "";
    };
  };
}
