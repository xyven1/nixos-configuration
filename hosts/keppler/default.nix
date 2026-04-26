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
    path = with pkgs; [coreutils gawk ipmitool];
    script = ''
      NUM_GOOD=4
      TARGET_FAN_SPD=5000

      GOOD_COUNT=0
      while [ $GOOD_COUNT -lt $NUM_GOOD ]; do
        FAN_SPD=$(ipmitool sensor reading "FAN1" | awk '{ print $3 }')
        if [ "$FAN_SPD" -gt "$TARGET_FAN_SPD" ]; then
          echo "Fan speed is too high ($FAN_SPD > $TARGET_FAN_SPD), setting..."
          ipmitool raw 0x30 0x45 0x01 0x01
          sleep 1
          ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x12
          GOOD_COUNT=0
        else
          echo "Fan speed is good ($FAN_SPD <= $TARGET_FAN_SPD)"
          GOOD_COUNT=$((GOOD_COUNT + 1))
        fi
        sleep 5
      done
      echo "Fan speed is stable, exiting."
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
