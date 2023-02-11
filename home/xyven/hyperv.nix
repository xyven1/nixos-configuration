{ inputs, outputs, lib, config, pkgs, ... }:

{
	imports = [
		./default.nix
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
	systemd.user.startServices = "sd-switch";
	home.stateVersion = "22.11";
}


