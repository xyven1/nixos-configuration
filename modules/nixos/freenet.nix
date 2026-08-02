{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.services.freenet-core;
  inherit (lib) mkEnableOption mkOption mkIf types literalExpression;

  boolFlag = name: value: lib.optional value name;
  optFlag = name: value: lib.optional (value != null) "${name}=${toString value}";

  stateDir = "%S/freenet";

  args =
    [cfg.mode]
    ++ optFlag "--network-address" cfg.networkAddress
    ++ optFlag "--network-port" cfg.networkPort
    ++ boolFlag "--is-gateway" cfg.isGateway
    ++ optFlag "--public-network-address" cfg.publicNetworkAddress
    ++ optFlag "--public-network-port" cfg.publicNetworkPort
    ++ optFlag "--ws-api-address" cfg.wsApiAddress
    ++ optFlag "--ws-api-port" cfg.wsApiPort
    ++ optFlag "--log-level" cfg.logLevel
    ++ ["--data-dir" stateDir "--config-dir" stateDir]
    ++ cfg.extraArgs;
in {
  options.services.freenet-core = {
    enable = mkEnableOption "the Freenet node (freenet-core)";

    package = mkOption {
      type = types.package;
      default = inputs.freenet-core.packages.${pkgs.system}.freenet;
      example =
        literalExpression
        "inputs.freenet-core.packages.\${pkgs.system}.default";
      description = ''
        The `freenet` package to run.
      '';
    };

    mode = mkOption {
      type = types.enum ["network" "local"];
      default = "network";
      description = ''
        Which `freenet` subcommand to run. "network" joins the real
        Freenet P2P network; "local" runs a standalone node with no P2P
        connectivity, useful for development.
      '';
    };

    isGateway = mkEnableOption "running this node as a Freenet gateway";

    networkAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind for P2P network traffic (UDP).";
    };

    networkPort = mkOption {
      type = types.nullOr types.port;
      default = null;
      example = 31337;
      description = ''
        UDP port to bind for P2P network traffic. Freenet picks a random
        port if unset, which is fine for an ordinary peer but you should
        set a fixed port for a gateway (and for `openFirewall` to work,
        since a random port can't be opened in advance).
      '';
    };

    publicNetworkAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Publicly reachable address for this node. Required when
        `isGateway` is set.
      '';
    };

    publicNetworkPort = mkOption {
      type = types.nullOr types.port;
      default = null;
      description = ''
        Publicly reachable UDP port for this node. Required when
        `isGateway` is set.
      '';
    };

    wsApiAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''
        Address for the WebSocket/HTTP API (and dashboard). Defaults to
        loopback-only, unlike upstream's own default of 0.0.0.0 - flip
        this deliberately if you want it reachable off-box, and consider
        a reverse proxy or VPN instead of exposing it directly.
      '';
    };

    wsApiPort = mkOption {
      type = types.port;
      default = 7509;
      description = "Port for the WebSocket/HTTP API and dashboard.";
    };

    logLevel = mkOption {
      type = types.enum ["trace" "debug" "info" "warn" "error"];
      default = "info";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Open the UDP `networkPort` (and `publicNetworkPort`, if
        different) in the firewall. Requires `networkPort` to be set.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["--bandwidth-limit" "10MB"];
      description = ''
        Extra command-line arguments appended verbatim, for flags this
        module doesn't wrap yet.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.isGateway -> (cfg.publicNetworkAddress != null && cfg.publicNetworkPort != null && cfg.networkPort != null);
        message = "services.freenet.isGateway requires networkPort, publicNetworkAddress and publicNetworkPort to be set.";
      }
      {
        assertion = cfg.openFirewall -> cfg.networkPort != null;
        message = "services.freenet.openFirewall requires services.freenet.networkPort to be set (can't pre-open a random port).";
      }
    ];

    networking.firewall = mkIf cfg.openFirewall {
      allowedUDPPorts = [cfg.networkPort];
    };

    systemd.services.freenet = {
      description = "Freenet node";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        FREENET_WEBAPP_CACHE_DIR = "${stateDir}/webapp-cache";
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} ${lib.escapeShellArgs args}";

        DynamicUser = true;
        StateDirectory = "freenet";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "freenet";

        Restart = "on-failure";
        RestartSec = "5s";
        # See the top-of-file note: 42 means "I need a new version", which
        # a Nix-managed binary can't fulfil at runtime. Fail loudly instead
        # of restart-looping.
        RestartPreventExitStatus = [42];

        # Hardening.
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        LockPersonality = true;
        # wasm jit
        MemoryDenyWriteExecute = false;
        SystemCallArchitectures = "native";
        SystemCallFilter = ["@system-service"];
        CapabilityBoundingSet = "";
        UMask = "0077";
      };
    };
  };
}
