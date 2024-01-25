{ lib, inputs, config, outputs, hostname, pkgs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    inputs.flake-utils-plus.nixosModules.autoGenFromInputs
    ./locale.nix
    ./sops.nix
    ./nix.nix
  ] ++ (builtins.attrValues outputs.nixosModules);
  # nixpkgs.config.useDefaultOverlays = true;
  environment.systemPackages = [
    pkgs.bash
    (pkgs.writeScriptBin
      "rb"
      ''
        #!/usr/bin/env bash
        sudo nixos-rebuild switch "$@"
      '')
  ];
  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    sharedModules = builtins.attrValues outputs.homeManagerModules;
    users =
      let
        getHomePath = user:
          let
            home-dir = ../../../home;
            home-subdirs = builtins.readDir home-dir;
            user-dir =
              if builtins.hasAttr user home-subdirs
                && home-subdirs.${user} == "directory" then
                builtins.readDir (home-dir + /${user})
              else { };
          in
          if builtins.hasAttr "${hostname}.nix" user-dir then
            home-dir + /${user}/${hostname}.nix
          else if builtins.hasAttr "generic.nix" user-dir then
            home-dir + /${user}/generic.nix
          else
            null;
      in
      builtins.listToAttrs (builtins.map
        (v: {
          name = v.user;
          value = import v.config_path;
        })
        (builtins.filter (v: v.config_path != null)
          (builtins.map
            (user: {
              inherit user;
              config_path = (getHomePath user);
            })
            (builtins.attrNames (lib.filterAttrs
              (n: v: v.isNormalUser)
              config.users.users)))
        ));
  };
}
