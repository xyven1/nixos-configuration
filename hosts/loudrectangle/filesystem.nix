{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/scsi-361866da075a8d2002a9c02590ebea32e";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = ["-f"];
            subvolumes = {
              "root" = {
                mountpoint = "/";
                mountOptions = ["noatime"];
              };
              "nix" = {
                mountpoint = "/nix";
                mountOptions = ["noatime"];
              };
              "home" = {
                mountpoint = "/home";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };
    };
  };
}
