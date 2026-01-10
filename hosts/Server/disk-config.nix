{lib, ...}: {
  # =============================================================================
  # DISKO CONFIGURATION - Reverse-engineered from running system state
  # =============================================================================
  # WARNING: This configuration is DESCRIPTIVE, not prescriptive.
  # It documents the EXISTING state of the ZFS pools and should NOT be used
  # to format/recreate the disks (would cause data loss).
  #
  # To test this generates correct fileSystems without formatting:
  #   nix build '.#nixosConfigurations.Server.config.system.build.diskoScript' --dry-run
  #
  # Physical Layout:
  # ----------------
  # sda (Samsung SSD 860 EVO 500GB) - System/Boot drive
  #   ├─ sda1: 512M EFI (BOOT_SATA) - mounted at /boot
  #   ├─ sda2: 199.5G ZFS (rpool special vdev mirror-1)
  #   └─ sda3: 265.8G ZFS (bpool_sata)
  #
  # sdb (Seagate 16TB ST16000VE002) - Data drive
  #   └─ sdb1: 14.6T ZFS (rpool mirror-0)
  #
  # sdc (Seagate 16TB ST16000NM001G) - Data drive
  #   └─ sdc1: 14.6T ZFS (rpool mirror-0)
  #
  # nvme0n1 (Crucial P3 Plus 1TB) - NVMe special vdev
  #   ├─ nvme0n1p1: 1M BIOS boot (unused)
  #   ├─ nvme0n1p2: 500M EFI (unused)
  #   └─ nvme0n1p3: 199.5G ZFS (rpool special vdev mirror-1)
  #
  # ZFS Pools:
  # ----------
  # rpool: Main data pool with mirror + special vdev
  #   - mirror-0: sdb1 + sdc1 (14.6T each, main storage)
  #   - special mirror-1: nvme0n1p3 + sda2 (199.5G each, metadata/small blocks)
  #   - Datasets: rpool/safe/data → /mnt/data
  #
  # bpool_sata: Boot/system pool (single disk)
  #   - sda3 (265.8G)
  #   - Datasets:
  #     - bpool_sata/local/root → / (root filesystem)
  #     - bpool_sata/safe/nix → /nix
  #     - bpool_sata/safe/persist → /persist
  # =============================================================================

  disko.devices = {
    # =========================================================================
    # DISK DEFINITIONS
    # =========================================================================

    # Samsung SSD 860 EVO 500GB - Boot/System drive
    disk.sata_ssd = {
      device = lib.mkDefault "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0NA15609K";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            label = "esp-sata";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["defaults"];
            };
          };
          rpool_special = {
            label = "special_mirror";
            size = "199.5G";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
          bpool = {
            label = "bpool_sata";
            size = "100%";
            content = {
              type = "zfs";
              pool = "bpool_sata";
            };
          };
        };
      };
    };

    # Seagate 16TB ST16000VE002 - Data mirror disk 1
    disk.data1 = {
      device = lib.mkDefault "/dev/disk/by-id/ata-ST16000VE002-3BR101_ZR700R8Z";
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

    # Seagate 16TB ST16000NM001G - Data mirror disk 2
    disk.data2 = {
      device = lib.mkDefault "/dev/disk/by-id/ata-ST16000NM001G-2KK103_ZL2EZ7VR";
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

    # Crucial P3 Plus 1TB NVMe - Special vdev for metadata
    disk.nvme = {
      device = lib.mkDefault "/dev/disk/by-id/nvme-CT1000P3PSSD8_240746F944B7";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          bios_boot = {
            size = "1M";
            type = "EF02"; # BIOS boot partition
          };
          esp_unused = {
            size = "500M";
            type = "EF00"; # EFI System Partition (not mounted)
            content = {
              type = "filesystem";
              format = "vfat";
              # Not mounted - boot uses SATA SSD ESP
            };
          };
          rpool_special = {
            size = "199.5G";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    # =========================================================================
    # ZFS POOL DEFINITIONS
    # =========================================================================

    zpool = {
      # -----------------------------------------------------------------------
      # rpool - Main data pool
      # Topology: mirror (2x16TB HDD) + special mirror (NVMe + SATA SSD)
      # -----------------------------------------------------------------------
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
            special = {
              members = ["nvme" "sata_ssd"];
            };
          };
        };
        rootFsOptions = {
          compression = "zstd";
          atime = "on";
          relatime = "on";
          xattr = "on";
          acltype = "off";
          dnodesize = "legacy";
        };
        # Note: ashift is auto-detected per vdev, no need to set explicitly

        datasets = {
          "safe" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
            };
          };
          "safe/data" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/mnt/data";
          };
        };
      };

      # -----------------------------------------------------------------------
      # bpool_sata - Boot/System pool
      # Single disk (SATA SSD partition 3)
      # Contains root, /nix, and /persist datasets
      # -----------------------------------------------------------------------
      bpool_sata = {
        type = "zpool";
        rootFsOptions = {
          compression = "zstd";
          atime = "on";
          relatime = "on";
          xattr = "on";
          acltype = "off";
          dnodesize = "legacy";
        };
        options = {
          ashift = "12";
        };

        datasets = {
          "local" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
            };
          };
          "local/root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/";
            postCreateHook = ''
              zfs snapshot bpool_sata/local/root@blank
            '';
          };
          "safe" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
            };
          };
          "safe/nix" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/nix";
          };
          "safe/persist" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/persist";
          };
        };
      };
    };
  };

  # =============================================================================
  # FILESYSTEM OVERRIDES
  # =============================================================================
  # Note: disko generates fileSystems entries from the datasets above.
  # These overrides ensure boot-critical mounts have neededForBoot = true,
  # and /boot uses the same UUID as the current running system.
  # =============================================================================

  fileSystems = {
    "/".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/persist".neededForBoot = true;
    # Override /boot to use UUID (matches current fstab) instead of partlabel
    "/boot".device = lib.mkForce "/dev/disk/by-uuid/E2E0-85F9";
  };

  # ---------------------------------------------------------------------------
  # Impermanence: Rollback root to blank snapshot on every boot
  # ---------------------------------------------------------------------------
  # This wipes / on each boot, keeping only what's persisted in /persist.
  # The snapshot bpool_sata/local/root@blank was created on Nov 14, 2025.
  # ---------------------------------------------------------------------------
  boot.initrd.postResumeCommands = lib.mkAfter ''
    zfs rollback -r bpool_sata/local/root@blank
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
