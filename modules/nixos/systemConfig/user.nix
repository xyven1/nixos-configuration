{ inputs, outputs, config, lib, pkgs, ... }:

let
  cfg = config.systemConfig;
in
{
  options.systemConfig = {
    users = lib.mkOption {
      default = [];
      type = lib.types.listOf lib.types.str;
    };
    home-manager = {
      enable = lib.mkEnableOption "home-manager";
      hostName = lib.mkOption {
        default = "generic";
        type = lib.types.str;
      };
    };
  };

  config = {
    home-manager = lib.mkIf cfg.home-manager.enable {
      # useGlobalPkgs = lib.mkDefault true;
      # useUserPackages = lib.mkDefault true;
      # extraSpecialArgs = { inherit inputs; };
      # sharedModules = builtins.attrValues outputs.homeManagerModules;

      users = builtins.listToAttrs (builtins.map (user:
      let
        home = if builtins.pathExists ../../../home/${user}/${cfg.home-manager.hostName}.nix then cfg.home-manager.hostName else "generic";
      in
      {
        name = user;
        value = import ../../../home/${user}/${home}.nix;
      }) cfg.users);
    };
    users = {
      users = builtins.listToAttrs (builtins.map (user: {
        name = user;
        value = {
          isNormalUser = true;
          extraGroups = lib.mkDefault [ "wheel" "networkmanager" ];
          packages = with pkgs; [ home-manager ];
        };
      }) cfg.users);
    };
  };
}

