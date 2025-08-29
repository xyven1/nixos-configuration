{
  description = "Xyven's NixOS config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # CachyOS kernel
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # to be removed
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";

    # overlays
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    wezterm.url = "github:wez/wezterm?dir=nix";

    # config
    neovim-config.url = "github:xyven1/neovim-config";
    neovim-config.flake = false;

    backgrounds.url = "github:xyven1/nixos-backgrounds";
    backgrounds.flake = false;

    # host specific
    # ockham
    home-management.url = "github:xyven1/home-management";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # work
    nixgl.url = "github:nix-community/nixGL";
    nixgl.inputs.nixpkgs.follows = "nixpkgs";
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
    devShell = forAllPkgs (pkgs: import ./shell.nix {inherit pkgs;});
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
          modules = [{home.username = hostUser.user;} hostUser.config_path] ++ builtins.attrValues outputs.homeManagerModules;
        };
      })
      homes);
  };
}
