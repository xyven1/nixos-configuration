{
  description = "Xyven's NixOS config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    rust-overlay.url = "github:oxalica/rust-overlay";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    neovim-config = {
      flake = false;
      url = "github:xyven1/neovim-config";
    };

    wpi-wireless-install.url = "github:xyven1/wpi-wireless-install";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    backgrounds = {
      flake = false;
      url = "github:xyven1/nixos-backgrounds";
    };

    home-management.url = "github:xyven1/home-management";

    sops-nix.url = "github:Mic92/sops-nix";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

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
    lib = nixpkgs.lib;
    forAllSystems = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems;
    forAllPkgs = f: forAllSystems (system: f nixpkgs.legacyPackages.${system});
    hosts =
      lib.filterAttrs
      (n: v:
        n
        != "common"
        && v == "directory"
        && builtins.hasAttr "default.nix" (builtins.readDir ./hosts/${n}))
      (builtins.readDir ./hosts);
  in {
    inherit lib;
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    packages = forAllPkgs (pkgs: import ./pkgs {inherit pkgs;});
    devShells = forAllPkgs (pkgs: import ./shell.nix {inherit pkgs;});
    formatter = forAllPkgs (pkgs: pkgs.nixpkgs-fmt);

    nixosConfigurations =
      builtins.mapAttrs
      (hostname: _:
        nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs outputs hostname;};
          modules = [./hosts/${hostname}];
        })
      hosts;

    homeConfigurations = let
      getHomePath = host: user: let
        home-dir = ./home;
        home-subdirs = builtins.readDir home-dir;
        user-dir =
          if
            builtins.hasAttr user home-subdirs
            && home-subdirs.${user} == "directory"
          then builtins.readDir (home-dir + /${user})
          else {};
      in
        if builtins.hasAttr "${host}.nix" user-dir
        then home-dir + /${user}/${host}.nix
        else if builtins.hasAttr "generic.nix" user-dir
        then home-dir + /${user}/generic.nix
        else null;
      getHostUsers = host: (builtins.attrNames (lib.filterAttrs
        (n: v: v.group == "users")
        outputs.nixosConfigurations.${host}.config.users.users));
      host_users =
        builtins.filter (v: v.config_path != null)
        # combine the results of each host to get a complete list of host/user combos
        (lib.flatten (
          lib.mapAttrsToList
          # take each host and map it to a list of attrsets of user and their config
          (host: _: (builtins.map
            (user: {
              inherit host user;
              config_path = getHomePath host user;
            })
            (getHostUsers host)))
          hosts
        ));
    in
      builtins.listToAttrs (
        builtins.map
        (v: {
          name = "${v.user}@${v.host}";
          value =
            home-manager.lib.homeManagerConfiguration
            {
              pkgs = nixpkgs.legacyPackages.x86_64-linux;
              extraSpecialArgs = {inherit inputs outputs;};
              modules =
                [
                  v.config_path
                ]
                ++ builtins.attrValues outputs.homeManagerModules;
            };
        })
        host_users
      );
  };
}
