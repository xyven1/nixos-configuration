{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./filesystem.nix
    ./services/ssh.nix
    ./services/unifi.nix

    ../common/global
    ../common/users/xyven
  ];

  boot.initrd.systemd.services."set-fan-speed" = {
    description = "Set fan speed via IPMI";
    wantedBy = ["initrd.target"];
    after = ["systemd-modules-load.service" "initrd-root-device.target"];
    serviceConfig = {
      Type = "oneshot";
      Path = [pkgs.ipmitool];
      ExecStart = ''
        ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x12
      '';
    };
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

  security.polkit.enable = true;

  system.stateVersion = "25.11";
}
