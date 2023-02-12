{
	description = "Xyven's NixOS config";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
		flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";

		home-manager.url = "github:nix-community/home-manager/release-22.11";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";

		neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
		neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
    neovim-config = {
      flake =false;
      url = "github:Xyven1/neovim-config";
    };

		disko.url = "github:nix-community/disko";
		disko.inputs.nixpkgs.follows = "nixpkgs";
	};
	outputs =
		{ self,
		nixpkgs,
		flake-utils,
		home-manager,
		...
		}@inputs:
		let
			inherit (self) outputs;
			forAllSystems = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems;
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
					modules = [ ./hosts/wsl ];
				};
				hyperv = nixpkgs.lib.nixosSystem {
					specialArgs = { inherit inputs outputs; };
					modules = [ ./hosts/hyperv ];
				};
				laptop = nixpkgs.lib.nixosSystem {
					specialArgs = { inherit inputs outputs; };
					modules = [ ./hosts/laptop ];
				};
			};

			homeConfigurations = {
				"xyven@hyperv" = home-manager.lib.homeManagerConfiguration {
					pkgs = nixpkgs.legacyPackages.x86_64-linux;
					extraSpecialArgs = { inherit inputs outputs; };
					modules = [
						./home/hyperv.nix
					];
				};
				"xyven@laptop" = home-manager.lib.homeManagerConfiguration {
					pkgs = nixpkgs.legacyPackages.x86_64-linux;
					extraSpecialArgs = { inherit inputs outputs; };
					modules = [
						./home/xyven/laptop.nix
					];
				};
			};
		};
}
