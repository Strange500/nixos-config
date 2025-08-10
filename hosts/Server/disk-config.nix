{lib, ...}: {
  disko.devices = {
    disk = {
      disk1 = {
        device = lib.mkDefault "/dev/vda";
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
            system = {
              name = "system";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-L" "nixos-system" "-f"];
                # Don't set mountpoint here since tmpfs handles root
                subvolumes = {
                  # Create a root subvolume but don't mount it at /
                  "@root" = {
                    mountOptions = ["compress=zstd" "noatime"];
                  };
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
                };
              };
            };
          };
        };
      };

      # New disk for Podman
      disk2 = {
        device = lib.mkDefault "/dev/vdb"; # change if your new disk has another path
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            podman = {
              name = "podman";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/var/lib/containers";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };
    };

    # Tmpfs for root - this takes precedence
    nodev = {
      root-tmpfs = {
        type = "nodev";
        fsType = "tmpfs";
        mountpoint = "/";
        mountOptions = ["mode=755" "size=4G"];
      };
    };
  };
  # boot = {
  #   initrd = {
  #     systemd = {
  #       enable = true;
  #       services.rollback = {
  #         description = "Rollback BTRFS root subvolume to a pristine state";
  #         wantedBy = ["initrd.target"];
  #         before = ["sysroot.mount"];
  #         after = ["systemd-udev-settle.service"];
  #         wants = ["systemd-udev-settle.service"];
  #         unitConfig.DefaultDependencies = "no";
  #         serviceConfig = {
  #           Type = "oneshot";
  #           RemainAfterExit = true;
  #         };
  #         script = ''
  #           set -euo pipefail

  #           # Wait for device to be available
  #           for i in {1..30}; do
  #             if [ -e /dev/disk/by-label/nixos-system ]; then
  #               break
  #             fi
  #             echo "Waiting for nixos-system device... ($i/30)"
  #             sleep 1
  #           done

  #           if [ ! -e /dev/disk/by-label/nixos-system ]; then
  #             echo "Error: nixos-system device not found"
  #             exit 1
  #           fi

  #           # Create temporary mount point
  #           mkdir -p /btrfs_tmp

  #           # Mount the btrfs filesystem (without subvol to access all subvolumes)
  #           mount -t btrfs /dev/disk/by-label/nixos-system /btrfs_tmp

  #           # Check if root subvolume exists
  #           if [ -d /btrfs_tmp/root ]; then
  #             echo "Found existing root subvolume, creating backup..."

  #             # Create old_roots directory if it doesn't exist
  #             mkdir -p /btrfs_tmp/old_roots

  #             # Create timestamp for backup
  #             timestamp=$(date "+%Y-%m-%d_%H:%M:%S")

  #             # Move current root to backup location
  #             mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
  #             echo "Moved root subvolume to old_roots/$timestamp"
  #           fi

  #           # Function to recursively delete subvolumes
  #           delete_subvolume_recursively() {
  #             local subvol_path="$1"
  #             if [ ! -d "$subvol_path" ]; then
  #               return
  #             fi

  #             # Delete child subvolumes first
  #             while IFS= read -r -d ''' subvol; do
  #               [ -n "$subvol" ] && delete_subvolume_recursively "/btrfs_tmp/$subvol"
  #             done < <(btrfs subvolume list -o "$subvol_path" 2>/dev/null | cut -f 9- -d ' ' | tr '\n' '\0' || true)

  #             echo "Deleting subvolume: $subvol_path"
  #             btrfs subvolume delete "$subvol_path" || echo "Warning: Failed to delete $subvol_path"
  #           }

  #           # Clean up old backups (older than 30 days)
  #           if [ -d /btrfs_tmp/old_roots ]; then
  #             echo "Cleaning up old backups..."
  #             find /btrfs_tmp/old_roots/ -maxdepth 1 -type d -mtime +30 | while read -r old_backup; do
  #               if [ "$old_backup" != "/btrfs_tmp/old_roots" ]; then
  #                 echo "Removing old backup: $old_backup"
  #                 delete_subvolume_recursively "$old_backup"
  #               fi
  #             done
  #           fi

  #           # Create new pristine root subvolume
  #           echo "Creating new root subvolume..."
  #           btrfs subvolume create /btrfs_tmp/root

  #           # Unmount
  #           umount /btrfs_tmp
  #           echo "Rollback completed successfully"
  #         '';
  #       };
  #     };
  #   };
  # };

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
