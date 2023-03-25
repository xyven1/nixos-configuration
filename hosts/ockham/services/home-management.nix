{ config, lib, inputs, pkgs, ... }:

with lib;

let
  cfg = config.services.homeManagement;
  username = "hmmngmnt";
in
{
  options = {
    services.homeManagement = {
      enable = mkEnableOption ''
        Home management server
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.${username} = {
      isSystemUser = true;
      description = "Home management daemon user";
      createHome = false;
      group = username;
    };
    users.groups.${username} = { };

    networking.firewall.allowedTCPPorts = [ 43434 ];

    systemd.services.homeManagement = {
      description = "Home management daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.nodejs ];

      serviceConfig = {
        User = username;
        WorkingDirectory = "${inputs.home-management.packages.x86_64-linux.home-management-server}/lib/node_modules/home-management-server";
        Restart = "on-failure";
        Environment = [ "SERVER_PORT=43434" "DIST_PATH=${inputs.home-management.packages.x86_64-linux.home-management}/lib/node_modules/home-management/dist" ];
        ExecStart = "${inputs.home-management.packages.x86_64-linux.home-management-server}/bin/home-management-server";
      };
      preStart = ''
      '';
    };

  };

}
