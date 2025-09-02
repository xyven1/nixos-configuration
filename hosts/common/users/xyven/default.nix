{
  pkgs,
  config,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  imports = [
    ../../optional/fish.nix
  ];
  users.users.xyven = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups =
      [
        "wheel"
      ]
      ++ ifTheyExist [
        "networkmanager"
        "docker"
        "libvirtd"
        "dialout"
        "minecraft"
      ];
  };
}
