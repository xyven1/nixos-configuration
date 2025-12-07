{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.secrets.cloudflare = {};
  custom.nginx = {
    enable = true;
    fqdn = "${config.networking.hostName}.adequately.run";
    localSubnet = "10.1.0.0/16";
    cloudflareCert = {
      email = "acme@xyven.dev";
      wildcard = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
    virtualHosts = {
      unifi.locations."/" = {
        host = "10.73.0.1";
        port = 8443;
        proxyHttps = true;
      };
      portal.locations."/" = {
        host = "10.73.0.1";
        port = 443;
        proxyHttps = true;
      };
    };
  };

  nixpkgs.allowUnfreePackages = [
    "unifi-controller"
    "mongodb"
  ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  systemd.services.unifi-netns = let
    ip = lib.getExe' pkgs.iproute2 "ip";
    ipt = lib.getExe' pkgs.iptables "iptables";
    subnet = "10.73.0";

    tableArg = ruleConf:
      if lib.isAttrs ruleConf && ruleConf ? table
      then "-t ${ruleConf.table}"
      else "";
    rule = ruleConf:
      if lib.isAttrs ruleConf
      then ruleConf.rule
      else ruleConf;
    createRule = ruleConf: ''
      ${ipt} ${tableArg ruleConf} -C ${rule ruleConf} 2>/dev/null \
        || ${ipt} ${tableArg ruleConf}  -A ${rule ruleConf}
    '';
    cleanRule = ruleConf: ''
      ${ipt} ${tableArg ruleConf} -D ${rule ruleConf} 2>/dev/null || true
    '';
    portConfToRules = portConf: let
      hostPort =
        if builtins.isAttrs portConf.port
        then portConf.port.host
        else portConf.port;
      netnsPort =
        if builtins.isAttrs portConf.port
        then portConf.port.netns
        else portConf.port;
    in [
      {
        table = "nat";
        rule = "PREROUTING -p ${portConf.proto} --dport ${toString hostPort} -j DNAT --to-destination ${subnet}.1:${toString netnsPort}";
      }
      "FORWARD -d ${subnet}.1 -p ${portConf.proto} --dport ${toString netnsPort} -j ACCEPT"
    ];
    ports = [
      {
        proto = "tcp";
        port = 8080;
      }
      {
        proto = "tcp";
        port = 6789;
      }
      {
        proto = "udp";
        port = 3478;
      }
      {
        proto = "udp";
        port = 10001;
      }
    ];
    rules = [
      # masquerade namespace → host/internet
      {
        table = "nat";
        rule = "POSTROUTING -s ${subnet}.1 ! -o unifi-host -j MASQUERADE";
      }
      # allow namespace → host/internet
      "FORWARD -i unifi-host -j ACCEPT"
      # allow established/related flows back into namespace
      "FORWARD -o unifi-host -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
    ];
    allRules = rules ++ (lib.concatMap portConfToRules ports);
  in {
    description = "Configure netns to unifi service inside";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = pkgs.writers.writeBash "unifi-wrapper-up" ''
        set -euo pipefail
        ${ip} netns add unifi
        ${ip} link add unifi-host type veth peer unifi-netns netns unifi
        ${ip} addr add ${subnet}.0/31 dev unifi-host
        ${ip} netns exec unifi ${ip} addr add ${subnet}.1/31 dev unifi-netns
        ${ip} link set unifi-host up
        ${ip} netns exec unifi ${ip} link set unifi-netns up
        ${ip} netns exec unifi ${ip} link set lo up
        ${ip} netns exec unifi ${ip} route replace default via ${subnet}.0

        ${lib.concatMapStrings createRule allRules}
      '';

      ExecStop = pkgs.writers.writeBash "unifi-wrapper-down" ''
        ${lib.concatMapStrings cleanRule allRules}

        ${ip} netns del unifi
        ${ip} link delete unifi-host
      '';
    };
  };
  services.unifi.enable = true;
  systemd.services.unifi = {
    after = ["unifi-netns.service"];
    bindsTo = ["unifi-netns.service"];
    serviceConfig = {
      AmbientCapabilities = lib.mkForce ["CAP_NET_BIND_SERVICE"];
      CapabilityBoundingSet = lib.mkForce ["CAP_NET_BIND_SERVICE"];
      PrivateUsers = lib.mkForce false;
      NetworkNamespacePath = "/var/run/netns/unifi";
    };
  };
  networking.firewall = {
    allowedTCPPorts = [
      80 # For nginx redirect
      443 # For nginx
      8080 # Port for UAP to inform controller.
      6789 # Port for UniFi mobile speed test.
    ];
    allowedUDPPorts = [
      3478 # UDP port used for STUN.
      10001 # UDP port used for device discovery.
    ];
  };
}
