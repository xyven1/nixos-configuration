{
  inputs,
  outputs,
  host,
  pkgs,
  lib,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.disko.nixosModules.disko
      inputs.flake-utils-plus.nixosModules.autoGenFromInputs
      ./locale.nix
      ./sops.nix
      ./nix.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);
  environment.systemPackages = [
    pkgs.bash
    pkgs.git
    pkgs.home-manager
    (pkgs.writeScriptBin
      "rb"
      ''
        #!/usr/bin/env bash
        sudo nixos-rebuild switch "$@"
      '')
  ];
  # enable overlays defined in overlay/default.nix
  nixpkgs.myOverlays.enable = lib.mkDefault true;
  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    sharedModules = builtins.attrValues outputs.homeManagerModules;
    users = builtins.listToAttrs (
      builtins.map
      (v: {
        name = v.user;
        value = import v.config_path;
      })
      (outputs.lib.getHostUsers host)
    );
  };
}
