{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.vopono;
  inherit (builtins) listToAttrs attrValues toString;
in {
  options = {
    services.vopono = {
      enable = mkEnableOption "vopono service";
      user = lib.mkOption {
        type = lib.types.str;
        default = "vopono";
        description = "User account under which vopono runs. Note that the user needs passwordless sudo access.";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "vopono";
        description = "Group under which vopono runs.";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/vopono";
        description = "Directory where vopono stores its data.";
      };
      provider = mkOption {
        description = "See vopono docs for valid providers.";
        type = types.str;
        example = "Mullvad";
      };
      protocol = mkOption {
        description = "See vopono docs for valid protocols.";
        type = types.str;
        example = "Wireguard";
      };
      server = mkOption {
        description = "See vopono docs for valid servers.";
        type = types.str;
        example = "usa-us";
      };
      package = mkOption {
        description = "The vopono package to use";
        type = types.package;
        default = pkgs.vopono;
      };
      interface = mkOption {
        type = types.str;
        default = "";
        description = "Optionally define the default interface. If not set, it uses the first interface on the system.";
      };
      namespace = mkOption {
        type = types.str;
        default = "sys_vo";
        example = "vopono";
        description = "Override the default, auto generated, namespace.";
      };
      services = mkOption {
        default = {};
        type = types.attrs;
        description = ''An attribute set with the name of a service where the value is a list of ports to forward to it.'';
        example = literalExpression ''
          { privoxy = [ 8118 ]; }
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    users.users = lib.mkIf (cfg.user == "vopono") {
      vopono = {
        group = cfg.group;
        uid = 388;
        home = cfg.dataDir;
        createHome = true;
      };
    };

    users.groups = lib.mkIf (cfg.group == "vopono") {
      vopono.gid = 388;
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "vopono-sync" ''
        set -eo pipefail
        [ -z "$SUDO_USER" ] && (echo "run with sudo"; exit 1)
        unset SUDO_USER
        ${lib.getExe cfg.package} sync --protocol ${cfg.protocol} ${cfg.provider}
      '')
    ];

    systemd.services = mkMerge [
      {
        vopono = {
          wantedBy = ["multi-user.target"];
          wants = ["network-online.target"];
          after = ["network-online.target"];
          path = with pkgs; [
            cfg.package
            wireguard-tools
            iproute2
            iptables
            procps
            systemd
            sudo
          ];

          unitConfig = {
            ConditionPathExists = "${cfg.dataDir}/.config/vopono";
          };
          environment = {
            RUST_LOG = "trace";
            HOME = cfg.dataDir;
          };
          serviceConfig = let
            ports = unique (flatten (attrValues cfg.services));
            portForwards = concatMapStrings (x: " -f ${toString x}") ports;
            interface =
              if cfg.interface != ""
              then "-i ${cfg.interface}"
              else "";
          in {
            Type = "notify";
            User = "root";
            Group = cfg.group;
            WorkingDirectory = cfg.dataDir;
            NotifyAccess = "all";
            Restart = "always";
            RestartSec = "5s";
            ExecStart = ''
              ${lib.getExe cfg.package} exec \
                --user ${cfg.user} \
                --group ${cfg.group} \
                --keep-alive \
                ${portForwards} \
                ${interface} \
                --allow-host-access \
                --provider ${cfg.provider} \
                --server ${cfg.server} \
                --protocol ${cfg.protocol} \
                --custom-netns-name ${cfg.namespace} \
                "systemd-notify --ready"
            '';
            # It fails to start if there's a device left over from the last time it ran, just purge it on stop.
            ExecStop = "${pkgs.iproute2}/bin/ip link delete ${cfg.namespace}_d || exit 0";
          };
        };
      }
      /*
      Tie each service to vopono. If vopono stops/starts, these services will as well.
      Also bind in the resolv.conf for working DNS service and set the namespace for the service.
      */
      (listToAttrs
        (map (x: {
          name = x;
          value = {
            after = ["vopono.service"];
            partOf = ["vopono.service"];
            wantedBy = ["vopono.service"];
            serviceConfig = {
              BindPaths = ["/etc/netns/${cfg.namespace}/resolv.conf:/etc/resolv.conf"];
              NetworkNamespacePath = "/var/run/netns/${cfg.namespace}";
            };
          };
        }) (attrNames cfg.services)))
    ];
  };
}
