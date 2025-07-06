{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../modules/system/tpm/tpm.nix
    ./disk-config.nix
  ];

  users.mutableUsers = false;

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;

  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/var/lib/systemd"
      "/etc/NetworkManager"
      "/etc/ssh"
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
    users.strange = {
      directories = [
        "Downloads"
        "nixos"
        ".cache"
        ".config"
        "wallpaper"

        {
          directory = ".ssh";
          mode = "0700";
        }
        ".mozilla"
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
        ".local"
      ];
      files = [
        ".zshrc"
        ".zprofile"
        ".zshenv"
        ".zlogin"
        ".zshhistory"
        ".gtkrc-2.0"
        ".stignore"
      ];
    };
  };

  boot = {
    initrd = {
      luks.devices = {
        cryptsystem = {
          device = lib.mkForce "/dev/nvme0n1p3";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
        cryptdata = {
          device = lib.mkForce "/dev/sda1";
          allowDiscards = true;
          bypassWorkqueues = true;
        };

        # postDeviceCommands = pkgs.lib.mkBefore ''
        #   ''
      };
      # supportedFilesystems = ["btrfs"];
      systemd = {
        enable = true;
        services.rollback = {
          description = "Rollback BTRFS root subvolume to a pristine state";
          wantedBy = ["initrd.target"];

          # LUKS/TPM process. If you have named your device mapper something other
          # than 'enc', then @enc will have a different name. Adjust accordingly.
          after = ["systemd-cryptsetup@cryptsystem.service" "systemd-cryptsetup@cryptdata.service"];

          # Before mounting the system root (/sysroot) during the early boot process
          before = ["sysroot.mount"];

          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
                        # Rollback for cryptsystem
                        mkdir -p /btrfs_tmp
                        mount -o subvol=/ /dev/mapper/cryptsystem /btrfs_tmp

                        if [[ -e /btrfs_tmp/root ]]; then
                          mkdir -p /btrfs_tmp/old_roots
                          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
                          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
                        fi

                        delete_subvolume_recursively() {
                          IFS=$'\n'
                          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                            delete_subvolume_recursively "/btrfs_tmp/$i"
                          done
                          btrfs subvolume delete "$1"
                        }

                        for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
                          delete_subvolume_recursively "$i"
                        done

                        btrfs subvolume create /btrfs_tmp/root
                        umount /btrfs_tmp

                        # Rollback for cryptdata
            mkdir -p /btrfs_data_tmp
            mount -o subvol=/ /dev/mapper/cryptdata /btrfs_data_tmp

            # Handle /home subvolume (if you want to reset it)
            if [[ -e /btrfs_data_tmp/home ]]; then
              mkdir -p /btrfs_data_tmp/old_homes
              timestamp=$(date --date="@$(stat -c %Y /btrfs_data_tmp/home)" "+%Y-%m-%-d_%H:%M:%S")
              mv /btrfs_data_tmp/home "/btrfs_data_tmp/old_homes/$timestamp"
            fi

            # Handle /data subvolume (if you want to reset it)
            if [[ -e /btrfs_data_tmp/data ]]; then
              mkdir -p /btrfs_data_tmp/old_data
              timestamp=$(date --date="@$(stat -c %Y /btrfs_data_tmp/data)" "+%Y-%m-%-d_%H:%M:%S")
              mv /btrfs_data_tmp/data "/btrfs_data_tmp/old_data/$timestamp"
            fi

            delete_data_subvolume_recursively() {
              IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_data_subvolume_recursively "/btrfs_data_tmp/$i"
              done
              btrfs subvolume delete "$1"
            }

            # Clean up old homes (if resetting /home)
            for i in $(find /btrfs_data_tmp/old_homes/ -maxdepth 1 -mtime +30); do
              delete_data_subvolume_recursively "$i"
            done

            # Clean up old data (if resetting /data)
            for i in $(find /btrfs_data_tmp/old_data/ -maxdepth 1 -mtime +30); do
              delete_data_subvolume_recursively "$i"
            done

            # Recreate subvolumes
            btrfs subvolume create /btrfs_data_tmp/home
            btrfs subvolume create /btrfs_data_tmp/data

            umount /btrfs_data_tmp
          '';
        };
      };
    };
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
