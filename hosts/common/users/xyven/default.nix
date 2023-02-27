{ pkgs, config, lib, outputs, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  systemConfig = {
    users = [ "xyven" ];
  };
}
