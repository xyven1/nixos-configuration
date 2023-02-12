{ inputs, outputs, lib, config, pkgs, ... }:

{
	imports = [
		./generic.nix
	];

	nixpkgs = {
		config = {
			allowUnfree = true;
		};
	};

	home = {
		username = "xyven";
		homeDirectory = "/home/xyven";
    packages = with pkgs; [
      firefox
    ];
	};

	programs.home-manager.enable = true;
	programs.git.enable = true;
	home.stateVersion = "22.11";
}


