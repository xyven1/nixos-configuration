{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.unpackerr;
in {
  options = {
    services.unpackerr = {
      enable = lib.mkEnableOption "unpackerr";

      package = lib.mkPackageOption pkgs "unpackerr" {};

      user = lib.mkOption {
        type = lib.types.str;
        default = "unpackerr";
        description = "User account under which unpackerr runs.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "unpackerr";
        description = "Group under which unpackerr runs.";
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Settings for unpackerr in TOML format.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.unpackerr = {
      description = "unpackerr";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "on-failure";
        WorkingDirectory = "/tmp";
      };
    };

    users.users = lib.mkIf (cfg.user == "unpackerr") {
      unpackerr = {
        group = cfg.group;
        uid = 389;
      };
    };

    users.groups = lib.mkIf (cfg.group == "unpackerr") {
      unpackerr.gid = 389;
    };
  };
}
