{
  description = "Xyven's NixOS config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";

    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs-unstable";
    neovim-config = {
      flake = false;
      url = "github:Xyven1/neovim-config";
    };

    backgrounds = {
      flake = false;
      url = "github:Xyven1/nixos-backgrounds";
    };

    home-management.url = "github:Xyven1/home-management";

    sops-nix.url = "github:Mic92/sops-nix";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    { self
    , nixpkgs
    , flake-utils
    , home-manager
    , ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems;
      forAllPkgs = f: forAllSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays = import ./overlay { inherit inputs; };
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      packages = forAllPkgs (pkgs: import ./pkgs { inherit pkgs; });
      devShells = forAllPkgs (pkgs: import ./shell.nix { inherit pkgs; });
      formatter = forAllPkgs (pkgs: pkgs.nixpkgs-fmt);

      nixosConfigurations = {
        festus = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/festus ];
        };
        ockham = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/ockham ];
        };
      };

      homeConfigurations = {
        "xyven@festus" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home/xyven/festus.nix
          ];
        };
        "xyven@ockham" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home/xyven/ockham.nix
          ];
        };
      };
    };
}
