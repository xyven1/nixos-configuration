{config, ...}: let
  bridgePort = 25208;
in {
  services.tor = {
    enable = true;
    openFirewall = true;
    relay.enable = true;
    relay.role = "bridge";
    settings.ORPort = 34650;
    settings.ContactInfo = "tor@xyven.dev";
    settings.Nickname = "AdequatelyRun";
    settings.ServerTransportListenAddr = "obfs4 0.0.0.0:${toString bridgePort}";
  };
  networking.firewall.allowedTCPPorts = [
    bridgePort
  ];
  services.freenet-core = {
    enable = true;
    openFirewall = true;
    networkPort = 47194;
  };
  custom.nginx.virtualHosts.freenet.locations."/".port = config.services.freenet-core.wsApiPort;
}
