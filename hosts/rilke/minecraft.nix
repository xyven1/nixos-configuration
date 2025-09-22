{
  lib,
  pkgs,
  config,
  ...
}: let
  username = "minecraft";
in {
  sops.secrets.mcrcon_pass = {
    owner = config.users.users.${username}.name;
    group = config.users.users.${username}.group;
    mode = "0440";
  };

  users.users.${username} = {
    isSystemUser = true;
    useDefaultShell = true;
    description = "Minecraft server service user";
    createHome = true;
    home = "/var/lib/${username}";
    group = username;
  };
  users.groups.${username} = {};

  networking.firewall.allowedTCPPorts = [25565];
  networking.firewall.allowedUDPPorts = [25565];

  environment.defaultPackages = [
    (pkgs.writeShellScriptBin "mcrcon" ''
      PASS=$(cat ${config.sops.secrets.mcrcon_pass.path})
      if [ -z "$PASS" ]; then
        echo "Cannot access mcrcon password file"
        exit 1
      fi
      ${lib.getExe pkgs.rlwrap} ${lib.getExe pkgs.mcrcon} -p "$PASS" "$@"
    '')
  ];

  systemd.services.minecraft = {
    description = "Minecraft daemon";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    path = [pkgs.jdk21_headless];

    serviceConfig = {
      Restart = "always";
      ExecStart = "${lib.getExe pkgs.bash} /var/lib/${username}/startserver-java9.sh";
      ExecStop = ''
        ${lib.getExe pkgs.bash} -c "${lib.getExe pkgs.mcrcon} -p $(cat ${config.sops.secrets.mcrcon_pass.path}) stop"
      '';
      TimeoutStopSec = "60";
      User = username;
      WorkingDirectory = "/var/lib/${username}";

      # Hardening
      CapabilityBoundingSet = [""];
      DeviceAllow = [""];
      LockPersonality = true;
      PrivateDevices = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };
}
