{ inputs, outputs, lib, config, pkgs, ... }:

{
	imports = [
		./generic.nix
	];

	home = {
    packages = with pkgs; [
      firefox
    ];
	};
  programs = {
    bash = {
      enable = true;
      shellAliases = {
        rebuild = "sudo nixos-rebuild switch --flake .#laptop";
        "rebuild-home" = "home-manager switch --flake .#xyven@laptop";
      };
    };
  };
}


