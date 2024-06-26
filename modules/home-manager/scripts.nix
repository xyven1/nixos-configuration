{
  pkgs,
  config,
  lib,
  ...
}: let
  l = lib;
  t = lib.types;
in {
  options = {
    rbh = {
      nixos-conf-dir = l.mkOption {
        type = t.path;
        default = "/etc/nixos";
        description = "The directory where the NixOS configuration is stored";
      };
      profile = l.mkOption {
        type = t.nullOr t.nonEmptyStr;
        default = null;
        description = "The name of the profile to use";
      };
    };
  };
  config = let
    cfg = config.rbh;
  in {
    home.packages = [
      (pkgs.writeScriptBin
        "rbh"
        ''
          #!/usr/bin/env bash
          home-manager switch --flake ${cfg.nixos-conf-dir}${l.optionalString (cfg.profile != null) "#"}${cfg.profile} "$@"
        '')
    ];
  };
}
