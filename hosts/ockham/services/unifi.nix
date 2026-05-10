{
  inputs,
  config,
  ...
}: {
  imports = [inputs.unifi-os-server.nixosModules.unifi-os-server];
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  services.unifi-os-server = {
    enable = true;
    uosSystemIP = config.custom.nginx.fqdn;
    openFirewallUiPort = true;
    openFirewallServicePorts = true;
  };
  custom.nginx.virtualHosts.unifi.locations."/" = {
    port = config.services.unifi-os-server.ports.ui;
    proxyHttps = true;
  };
  virtualisation.oci-containers.containers.unifi-os-server = {
    extraOptions = [
      "--pids-limit=8192"
    ];
  };
}
