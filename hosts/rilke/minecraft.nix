{
  lib,
  pkgs,
  ...
}: let
  username = "minecraft";
in {
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
    path = [pkgs.jre];

    serviceConfig = {
      Restart = "always";
      ExecStart = "/var/lib/${username}/startserver.sh";
      ExecStop = "${lib.getExe pkgs.mcrcon} stop";
      TimeoutStopSec = "20";
      User = username;
      WorkingDirectory = "/var/lib/${username}";
    };
  };
}
