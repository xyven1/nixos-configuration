{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./filesystem.nix
    ./services/ssh.nix
    ./services/unifi.nix
    ./services/monitoring.nix

    ../common/global
    ../common/users/xyven
  ];

  systemd.services.set-fan-speed = {
    description = "Set fan speed via IPMI";
    wantedBy = ["multi-user.target"];
    unitConfig = {
      ConditionPathExists = "/dev/ipmi0";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [coreutils ipmitool];
    script = ''
      ipmitool raw 0x30 0x45 0x01 0x01
      sleep 1
      ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x12
    '';
  };

  hardware.enableRedistributableFirmware = true;

  networking.domain = "adequately.run";

  services.kmscon = {
    enable = true;
    fonts = [
      {
        name = "JetBrains Mono";
        package = pkgs.jetbrains-mono;
      }
      {
        name = "Symbols Nerd Font";
        package = pkgs.nerd-fonts.symbols-only;
      }
    ];
    hwRender = true;
  };

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

  security.polkit.enable = true;

  system.stateVersion = "25.11";
}
