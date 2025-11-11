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
          # ----- 1M GRUB boot partition (BIOS) --------------------
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };

          # ----- EFI (vfat) ---------------------------------------
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

          # ----- Btrfs system (your exact sub-volumes) ------------
          system = {
            name = "system";
            size = "7G"; # use full disk (cache will be on RAID)
            content = {
              type = "btrfs";
              extraArgs = ["-L" "nixos-system" "-f"];
              subvolumes = {
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@var-log" = {
                  mountpoint = "/var/log";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = ["compress=zstd" "noatime"];
                };
              };
            };
          };
          cache = {
            name = "cache";
            size = "100%"; # everything left
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/mnt/cache";
            };
          };
        };
      };
    };

    # ================================================================
    # 2. HDDs – data-only RAID-1 components
    # ================================================================
    disk.hdd-data = {
      device = lib.mkDefault "/dev/sdb"; # ← EXISTING XFS WITH DATA
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          mdadm = {
            size = "100%";
            content = {
              type = "mdraid";
              name = "raid1";
            };
          };
        };
      };
    };

    disk.hdd-mirror = {
      device = lib.mkDefault "/dev/sdc"; # ← EMPTY
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          mdadm = {
            size = "100%";
            content = {
              type = "mdraid";
              name = "raid1";
            };
          };
        };
      };
    };

    # ================================================================
    # 3. RAID-1 array – data only, degraded, data-preserving
    # ================================================================
    mdadm.raid1 = {
      type = "mdadm";
      level = 1;
      metadata = "1.2";
      content = {
        type = "filesystem";
        format = "xfs";
        mountpoint = "/mnt/raid";
      };
    };

    # ================================================================
    # 4. tmpfs root (your existing behavior)
    # ================================================================
    nodev.root-tmpfs = {
      fsType = "tmpfs";
      mountpoint = "/";
      mountOptions = ["mode=755" "size=4G"];
    };
  };

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
