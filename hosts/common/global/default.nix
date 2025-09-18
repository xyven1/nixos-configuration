{
  inputs,
  outputs,
  config,
  host,
  pkgs,
  lib,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote
      ./input.nix
      ./locale.nix
      ./sops.nix
      ./nix.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  environment.systemPackages = [
    pkgs.bash
    pkgs.git
    pkgs.home-manager
    (pkgs.writeShellScriptBin "rb" ''
      sudo nixos-rebuild switch "$@"
    '')
  ];
  networking.hostName = host;
  # Use more modern implementations for various things
  system.rebuild.enableNg = true;
  boot = {
    initrd.systemd.enable = true;
    loader.systemd-boot.enable = lib.mkIf (!config.boot.lanzaboote.enable) true;
  };
  networking.networkmanager.wifi.backend = "iwd";
  services.dbus.implementation = "broker";
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
