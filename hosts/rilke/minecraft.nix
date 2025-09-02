{
  lib,
  pkgs,
  config,
  ...
}: let
  username = "minecraft";
in {
  sops.secrets.mcrcon_pass = {};

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
    };
  };
}
