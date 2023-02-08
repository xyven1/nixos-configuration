{
	description = "Xyven's NixOS config";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
		nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
		nixos-hardware.url = "github:NixOS/nixos-hardware/master";
		flake-utils.url = "github:numtide/flake-utils";
		home-manager.url = "github:nix-community/home-manager/release-22.11";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";
		neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
		neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
	};
	outputs = 
		{ self,
		nixpkgs,
		nixpkgs-unstable,
		nixos-hardware,
		flake-utils,
		home-manager,
		neovim-nightly-overlay,
		... 
		}@inputs:
		let
			inherit (self) outputs;
			forAllSystems = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems;
			defaultModules = [
				home-manager.nixosModules.home-manager
			];
		in
		rec {
			overlays = import ./overlay { inherit inputs outputs; };
			nixosModules = import ./modules/nixos;
			homeManagerModules = import ./modules/home-manager;

			packages = forAllSystems (system:
				let pkgs = nixpkgs.legacyPackages.${system};
				in import ./pkgs { inherit pkgs; }
			);

			devShells = forAllSystems (system:
				let pkgs = nixpkgs.legacyPackages.${system};
				in import ./shell.nix { inherit pkgs; }
			);

			nixosConfigurations = {
				wsl = nixpkgs.lib.nixosSystem {
					specialArgs = { inherit inputs outputs; };
					modules =  (builtins.attrValues nixosModules) ++ defaultModules ++ [ 
						./hosts/wsl 
					];
				};
				hyperv = nixpkgs.lib.nixosSystem {
					specialArgs = { inherit inputs outputs; };
					modules =  (builtins.attrValues nixosModules) ++ defaultModules ++ [ 
						./hosts/hyperv 
					];
				};
			};

			homeConfigurations = {
				"xyven@hyperv" = home-manager.lib.homeManagerConfiguration {
					pkgs = nixpkgs.legacyPackages.x86_64-linux;
					extraSpecialArgs = { inherit inputs outputs; };
					modules = (builtins.attrValues homeManagerModules) ++ [
						./home/hyperv.nix 
					];
				};
			};
		};
}
