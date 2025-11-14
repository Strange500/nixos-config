{lib, ...}: {
  disko.devices = {
    disk.nvme = {
      device = lib.mkDefault "/dev/sda";
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

          zfs = {
            size = "5G";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };

          system = {
            name = "system";
            size = "100%";
            content = {
              type = "zfs";
              pool = "bpool";
            };
          };
        };
      };
    };

    disk.data1 = {
      device = lib.mkDefault "/dev/sdb"; # /dev/sdb
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };
    disk.data2 = {
      device = lib.mkDefault "/dev/sdc"; # /dev/sdc
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool = {
      rpool = {
        type = "zpool";
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                mode = "mirror";
                members = ["data1" "data2"];
              }
            ];
            special = [
              {
                members = ["nvme"];
              }
            ];
          };
        };
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };

        datasets = {
          "safe/data" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              special_small_blocks = "128K";
            };
            mountpoint = "/mnt/data";
          };
        };
      };
      bpool = {
        type = "zpool";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        datasets = {
          "local/root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/";
            postCreateHook = ''
              zfs snapshot bpool/local/root@blank
            '';
          };
          "safe/persist" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              special_small_blocks = "128K";
            };
            mountpoint = "/persist";
          };
          "safe/nix" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              special_small_blocks = "128K";
            };
            mountpoint = "/nix";
          };
        };
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "bpool/local/root";
      fsType = "zfs";
    };
    "/nix" = {
      device = "bpool/safe/nix";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/persist" = {
      device = "bpool/safe/persist";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/mnt/data" = {
      device = "rpool/safe/data";
      fsType = "zfs";
    };
  };

  # Rollback root on boot
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zpool import -a
    zfs rollback -r bpool/local/root@blank
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
