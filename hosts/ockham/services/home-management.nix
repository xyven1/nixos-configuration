{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  cfg = config.services.home-management;
in {
  options = {
    services.home-management = {
      enable = lib.mkEnableOption ''
        Home management server
      '';
      user = lib.mkOption {
        type = lib.types.str;
        default = "hmmngmnt";
        description = ''
          User account under which the home management server runs.
        '';
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "hmmngmnt";
        description = ''
          Group under which the home management server runs.
        '';
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 43434;
        description = ''
          Port on which the home management server listens.
        '';
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = inputs.home-management.packages.x86_64-linux.home-management;
        defaultText = lib.literalExpression "inputs.home-management.packages.x86_64-linux.home-management";
        description = ''
          The home management server package to use.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
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

    systemd.services.home-management = {
      description = "Home management daemon";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      wants = ["network.target"];

      environment = {
        SERVER_PORT = toString cfg.port;
      };
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "${cfg.package}/lib/node_modules/.bin";
        Restart = "on-failure";
        ExecStart = "${cfg.package}/lib/node_modules/.bin/home-management-server";
      };
    };

    users.users = lib.mkIf (cfg.user == "hmmngmnt") {
      hmmngmnt = {
        group = cfg.group;
        isSystemUser = true;
        description = "Home management daemon user";
      };
    };
    users.groups = lib.mkIf (cfg.group == "hmmngmnt") {
      hmmngmnt = {};
    };
  };
}
