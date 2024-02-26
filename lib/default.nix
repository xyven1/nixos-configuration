{
  outputs,
  lib,
  ...
}: {
  getHomePath = host: user: let
    home-dir = ../home;
    home-subdirs = builtins.readDir home-dir;
    user-dir =
      if
        builtins.hasAttr user home-subdirs
        && home-subdirs.${user} == "directory"
      then builtins.readDir (home-dir + /${user})
      else {};
  in
    if builtins.hasAttr "${host}.nix" user-dir
    then home-dir + /${user}/${host}.nix
    else if builtins.hasAttr "generic.nix" user-dir
    then home-dir + /${user}/generic.nix
    else null;
  getAllHostUsers = host:
    builtins.map
    (user: {
      inherit host user;
      config_path = outputs.lib.getHomePath host user;
    })
    (builtins.attrNames (lib.filterAttrs
      (n: v: v.isNormalUser)
      outputs.nixosConfigurations.${host}.config.users.users));
  getHostUsers = host:
    builtins.filter
    (v: v.config_path != null)
    (outputs.lib.getAllHostUsers host);
}
