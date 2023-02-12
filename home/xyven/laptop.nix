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
}


