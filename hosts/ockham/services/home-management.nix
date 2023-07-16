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

    networking.firewall.allowedTCPPorts = [ 8080 8443 43434 ];
    networking.firewall.allowedUDPPortRanges = [
      { from = 3475; to = 3478; }
      { from = 5223; to = 5228; }
      { from = 8445; to = 8663; }
    ];
    networking.firewall.allowedTCPPortRanges = [
      { from = 3475; to = 3478; }
      { from = 5223; to = 5228; }
      { from = 8445; to = 8663; }
    ];
    networking.firewall.enable = mkForce false;

    systemd.services.homeManagement = {
      description = "Home management daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.nodejs_18 ];

      serviceConfig = {
        User = username;
        WorkingDirectory = "${inputs.home-management.packages.x86_64-linux.home-management}/lib/node_modules/.bin";
        Restart = "on-failure";
        Environment = [ "SERVER_PORT=43434" ];
        ExecStart = "${inputs.home-management.packages.x86_64-linux.home-management}/lib/node_modules/.bin/home-management-server";
      };
      preStart = ''
      '';
    };

  };

}
