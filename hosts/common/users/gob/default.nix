{ pkgs, config, lib, outputs, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.users.gob = {
    isNormalUser = true;
    shell = pkgs.bash;
    extraGroups = [
      "wheel"
    ] ++ ifTheyExist [
      "networkmanager"
      "docker"
      "libvirtd"
    ];
  };
}
