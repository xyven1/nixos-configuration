{disks ? ["/dev/vdb"], ...}: {
  disk = {
    vdb = {
      type = "disk";
      device = builtins.elemAt disks 0;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            start = "1M";
            end = "100M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          luks = {
            start = "100M";
            end = "500000M";
            content = {
              type = "luks";
              name = "crypted";
              keyFile = "/tmp/secret.key";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };
  };
  lvm_vg = {
    pool = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "400G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [
              "defaults"
            ];
          };
        };
        swap = {
          size = "32G";
          content = {
            type = "swap";
            format = "ext4";
            mountpoint = "/swap";
          };
        };
      };
    };
  };
}
