{lib, ...}: {
  disko.devices = {
    # ================================================================
    # 1. NVMe – EFI + Btrfs system (exactly your original layout)
    # ================================================================
    disk.nvme = {
      device = lib.mkDefault "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # ----- 1M GRUB BIOS boot (kept for legacy BIOS) -----
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };

          # ----- EFI (vfat) ---------------------------------
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

          # ----- ZFS pool (takes the rest of the NVMe) ------
          l2arc = {
            size = "256G"; # Adjust: 64G–1T depending on NVMe size
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    disk.hdd-data = {
      device = lib.mkDefault "/dev/disk/by-id/ata-YOUR_EXISTING_HDD"; # /dev/sdb
      type = "disk";
      content = {
        type = "zfs";
        pool = "rpool";
      };
    };
    disk.hdd-mirror = {
      device = lib.mkDefault "/dev/disk/by-id/ata-YOUR_EMPTY_HDD"; # /dev/sdc
      type = "disk";
      content = {
        type = "zfs";
        pool = "rpool";
      };
    };

    # 3. ZFS Pool: Mirror HDDs + NVMe L2ARC
    zpool.rpool = {
      type = "zpool";
      mode = "mirror"; # RAID-1 on the two HDDs
      rootFsOptions = {
        compression = "lz4";
        "com.sun:auto-snapshot" = "false";
        ashift = "12"; # 4K sectors
      };
      datasets = {
        "local/root" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/";
          postCreateHook = ''
            zfs snapshot rpool/local/root@blank
          '';
        };
        "local/nix" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/nix";
        };
        "safe/persist" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/persist";
        };
        "data/cache" = {
          # Your large cache (persistent, mirrored + L2ARC)
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/mnt/cache";
        };
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "rpool/local/root";
      fsType = "zfs";
    };
    "/nix" = {
      device = "rpool/local/nix";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/persist" = {
      device = "rpool/safe/persist";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/mnt/cache" = {
      device = "rpool/data/cache";
      fsType = "zfs";
    };
  };

  # Rollback root on boot
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zpool import -a
    zfs rollback -r rpool/local/root@blank
  '';

  environment.persistence = {
    "/persist" = {
      enable = true;
      hideMounts = true;
      directories = [
        "/var/lib/sops"
        "/var/lib/nixos"
        "/var/lib/bluetooth"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
        "/var/lib/systemd"
        "/etc/NetworkManager"
        "/root/.ssh"
        {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
          mode = "u=rwx,g=rx,o=";
        }
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
        {
          file = "/var/keys/secret_file";
          parentDirectory = {mode = "u=rwx,g=,o=";};
        }
      ];
    };
  };
}
