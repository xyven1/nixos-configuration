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
      ];
    packages = with pkgs; [home-manager];
  };
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };
}
