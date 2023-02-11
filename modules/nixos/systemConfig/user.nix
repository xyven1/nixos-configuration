{ inputs, outputs, config, lib, pkgs, ... }:

let
  cfg = config.systemConfig;
in
{
  options.systemConfig = {
    user = lib.mkOption {
      default = "longer";
      type = lib.types.str;
    };
    home-manager = {
      enable = lib.mkEnableOption "home-manager";
      home = lib.mkOption {
        default = ../../../home;
        type = lib.types.path;
      };
    };
  };

  config = {
    home-manager = lib.mkIf cfg.home-manager.enable {
      useGlobalPkgs = lib.mkDefault true;
      useUserPackages = lib.mkDefault true;
      extraSpecialArgs = { inherit inputs; };
      sharedModules = builtins.attrValues outputs.homeManagerModules;
      users."${cfg.user}" = import cfg.home-manager.home;
    };
    users = {
      users.${cfg.user} = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "keys" ];
      };
    };
  };
}

