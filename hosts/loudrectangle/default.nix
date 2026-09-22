{...}: {
  imports = [
    ./hardware-configuration.nix
    ./filesystem.nix

    ../common/global
    ../common/users/xyven
    ../common/users/greg
    ../common/optional/kmscon.nix
  ];

  hardware.enableRedistributableFirmware = true;

  networking.domain = "adequately.run";

  networking.useDHCP = true;
  networking.nftables.enable = true;
  security.polkit.enable = true;

  /*
     sops.secrets.cloudflare = {};
  custom.nginx = {
    enable = true;
    fqdn = "${config.networking.hostName}.${config.networking.domain}";
    localSubnet = "10.1.0.0/16";
    cloudflareCert = {
      email = "acme@xyven.dev";
      wildcard = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };
  */

  system.stateVersion = "26.05";
}
