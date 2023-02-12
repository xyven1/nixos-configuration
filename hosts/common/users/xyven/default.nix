{ pkgs, config, lib, outputs, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  # users.mutableUsers = false;
  users.users.xyven = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    packages = with pkgs; [ home-manager ];
  };
  home-manager.users.xyven = import home/${config.networking.hostName}.nix;
}
