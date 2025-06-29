# Example to create a bios compatible gpt partition with second SSD
{ lib, ... }:
{
  disko.devices = {
    disk = {
      disk1 = {
        device = lib.mkDefault "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };
            esp = {
              name = "ESP";
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };

      # Second SSD - Option 1: Add to existing LVM volume group
      disk2 = {
        device = lib.mkDefault "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            lvm = {
              name = "lvm";
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool";  # Same volume group as disk1
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
            size = "30%FREE";  # Adjusted to leave space for other volumes
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
            };
          };
          # Example additional logical volume using the extra space
          home = {
            size = "70%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
              mountOptions = [
                "defaults"
              ];
            };
          };
        };
      };
    };
  };
}