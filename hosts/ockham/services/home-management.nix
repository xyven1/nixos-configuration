{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.homeManagement;
  username = "hmmngmnt";
in {
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
    users.groups.${username} = {};

    networking.firewall.allowedTCPPorts = [8080 8443];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 3475;
        to = 3478;
      }
      {
        from = 5223;
        to = 5228;
      }
      {
        from = 8445;
        to = 8663;
      }
    ];
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 3475;
        to = 3478;
      }
      {
        from = 5223;
        to = 5228;
      }
      {
        from = 8445;
        to = 8663;
      }
    ];
    networking.firewall.extraPackages = [pkgs.ipset];
    networking.firewall.extraCommands = ''
      if ! ipset --quiet list upnp; then
        ipset create upnp hash:ip,port timeout 3
      fi
      iptables -A OUTPUT -d 239.255.255.250/32 -p udp -m udp --dport 1900 -j SET --add-set upnp src,src --exist
      iptables -A nixos-fw -p udp -m set --match-set upnp dst,dst -j nixos-fw-accept
    '';

    systemd.services.homeManagement = {
      description = "Home management daemon";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      wants = ["network.target"];
      path = [pkgs.nodejs_18];

      serviceConfig = {
        User = username;
        WorkingDirectory = "${inputs.home-management.packages.x86_64-linux.home-management}/lib/node_modules/.bin";
        Restart = "on-failure";
        Environment = ["SERVER_PORT=43434"];
        ExecStart = "${inputs.home-management.packages.x86_64-linux.home-management}/lib/node_modules/.bin/home-management-server";
      };
      preStart = ''
      '';
    };
  };
}
