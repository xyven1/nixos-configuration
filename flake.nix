{
  description = "Xyven's NixOS config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    # to be removed
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";

    # overlays
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    rust-overlay.url = "github:oxalica/rust-overlay";

    # config
    neovim-config.url = "github:xyven1/neovim-config";
    neovim-config.flake = false;

    backgrounds.flake = false;
    backgrounds.url = "github:xyven1/nixos-backgrounds";

    # host specific
    # festus
    wpi-wireless-install.url = "github:xyven1/wpi-wireless-install";

    # ockham
    home-management.url = "github:xyven1/home-management";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems;
    forAllPkgs = f: forAllSystems (system: f nixpkgs.legacyPackages.${system});
    hosts = builtins.attrNames (nixpkgs.lib.filterAttrs
      (n: v:
        (n != "common")
        && v == "directory"
        && builtins.hasAttr "default.nix" (builtins.readDir ./hosts/${n}))
      (builtins.readDir ./hosts));
    homes =
      builtins.concatMap
      (user:
        builtins.map
        (hostFile: {
          inherit user;
          host = nixpkgs.lib.removeSuffix ".nix" hostFile;
          config_path = ./home/${user}/${hostFile};
        })
        (builtins.attrNames (nixpkgs.lib.filterAttrs
          (n: v: v == "regular")
          (builtins.readDir ./home/${user}))))
      (builtins.attrNames (nixpkgs.lib.filterAttrs
        (n: v: v == "directory" && n != "common")
        (builtins.readDir ./home)));
  in {
    lib = import ./lib {
      inherit inputs outputs;
      lib = nixpkgs.lib;
    };
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    packages = forAllPkgs (pkgs: import ./pkgs {inherit pkgs;});
    devShells = forAllPkgs (pkgs: import ./shell.nix {inherit pkgs;});
    formatter = forAllPkgs (pkgs: pkgs.alejandra);

    nixosConfigurations = builtins.listToAttrs (builtins.map
      (host: {
        name = host;
        value = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs outputs host;};
          modules = [./hosts/${host}];
        };
      })
      hosts);

    homeConfigurations = builtins.listToAttrs (builtins.map
      (hostUser: {
        name =
          if hostUser.host == "generic"
          then hostUser.user
          else "${hostUser.user}@${hostUser.host}";
        value = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {inherit inputs outputs;};
          modules = [hostUser.config_path] ++ builtins.attrValues outputs.homeManagerModules;
        };
      })
      homes);
  };
}
