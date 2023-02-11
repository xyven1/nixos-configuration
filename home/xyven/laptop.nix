{ inputs, outputs, lib, config, pkgs, ... }:

{
	imports = [
		./default.nix
    ./config/font.nix
	];

	nixpkgs = {
		config = {
			allowUnfree = true;
		};
	};

	home = {
		username = "xyven";
		homeDirectory = "/home/xyven";
	};


	programs.home-manager.enable = true;
	programs.git.enable = true;
	home.stateVersion = "22.11";
}


