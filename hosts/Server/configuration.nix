{
  inputs,
  config,
  pkgs,
  ...
}: let
  app = pkgs.writeShellApplication {
    name = "cache-cleaner";
    runtimeInputs = with pkgs; [coreutils findutils rsync gawk];
    text = ''
              #!/bin/bash
      # Exit on error, unset variable, or pipe failure
      set -euo pipefail

      CACHE="/mnt/cache"
      RAID="/mnt/raid"
      THRESHOLD=80
      # Renamed for clarity: we want to get usage *down to* this level.
      TARGET_USAGE=20

      # === Robustness Checks ===
      if ! [ -d "$CACHE" ]; then
        echo "Error: Cache directory $CACHE does not exist." >&2
        exit 1
      fi
      if ! [ -d "$RAID" ]; then
        echo "Error: RAID directory $RAID does not exist." >&2
        exit 1
      fi
      if ! touch "$RAID/.writable_test" 2>/dev/null; then
        echo "Error: RAID directory $RAID is not writable." >&2
        exit 1
      fi
      rm -f "$RAID/.writable_test"

      # === Get Current Usage ===
      # Using awk for slightly more robust parsing
      USED=$(df -kP "$CACHE" | tail -1 | awk '{print $5}' | tr -d '%')
      echo "[$(date)] Cache usage: $USED%"

      if [ "$USED" -lt "$THRESHOLD" ]; then
        echo "Under $THRESHOLD%. Skipping."
        exit 0
      fi

      echo "Over $THRESHOLD%. Starting cleanup..."

      # === Efficiency: Generate file list ONCE ===
      # Create a temp file
      FILE_LIST_FILE=$(mktemp)
      # Ensure temp file is always removed on script exit
      trap 'rm -f "$FILE_LIST_FILE"' EXIT HUP INT TERM

      echo "Generating file list (this may take a moment)..."
      # Find all files, sort by size (numeric, reverse), and save to the temp file
      # We redirect find's errors (e.g., permission denied) to /dev/null
      find "$CACHE" -type f -printf '%s %p\n' 2>/dev/null | sort -nr > "$FILE_LIST_FILE"

      # Check if we found any files at all
      if ! [ -s "$FILE_LIST_FILE" ]; then
          echo "No files found to move."
          exit 0
      fi

      # === Main Loop ===
      # Read the sorted list from our temp file, line by line
      while read -r LINE; do
        # Check current usage *before* moving the next file
        # This is fast and ensures we stop as soon as the target is met.
        USED=$(df -kP "$CACHE" | tail -1 | awk '{print $5}' | tr -d '%')
        if [ "$USED" -le "$TARGET_USAGE" ]; then
          echo "Reached target usage of $TARGET_USAGE%. Stopping."
          break
        fi

        # Extract the file path from the line "SIZE /path/to/file"
        FILE=$(echo "$LINE" | cut -d' ' -f2-)

        # Check if the file still exists (it might have been deleted by another process)
        if ! [ -f "$FILE" ]; then
          echo "Skipping (file no longer exists): $FILE"
          continue
        fi

        SIZE_HUMAN=$(du -h "$FILE" | cut -f1)
        echo "Moving $SIZE_HUMAN: $FILE → $RAID/"

        # Move the file
        if ! rsync -aHAXx --inplace --remove-source-files "$FILE" "$RAID/"; then
            echo "Error during rsync (RAID disk full?). Aborting." >&2
            break # Stop the loop on rsync failure
        fi

      done < "$FILE_LIST_FILE" # This pipes the file contents into the 'while read' loop

      # Final status report
      USED=$(df -kP "$CACHE" | tail -1 | awk '{print $5}' | tr -d '%')
      echo "[$(date)] Cleanup complete. Cache: $USED%"
    '';
  };
in {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    #../../modules/server
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  users.mutableUsers = false;
  users.users.${config.qgroget.user.username} = {
    # required for auto start containers auto start
    linger = true;
    # required for rootless container with multiple users
    autoSubUidGidRange = true;
  };

  # -----------------------------------------------------------------
  # ZFS global options (kernel modules, host-id, etc.)
  # -----------------------------------------------------------------
  boot.supportedFilesystems = ["zfs"];
  networking.hostId = "8425e3c1"; # <-- generate with `head -c4 /dev/urandom | od -An -t u4`
  services.zfs = {
    trim.enable = true;
    autoSnapshot.enable = false; # we manage our own blank snapshot
  };
  boot.kernelPackages = pkgs.linuxPackages_latest; # newest ZFS
  boot.initrd.kernelModules = ["zfs" "xfs" "btrfs" "nvme"];

  boot.swraid.enable = true;

  # === DEPENDENCY-SAFE SCRIPT: cache-cleaner ===
  environment.systemPackages = [
    pkgs.fuse-overlayfs
    pkgs.mergerfs
    pkgs.mergerfs-tools
    app
  ];

  # === SYSTEMD: Run every 15 minutes ===
  systemd.services.cache-cleaner = {
    description = "Auto-move large torrents from NVMe to RAID when 80% full";
    after = ["data.mount"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${app}/bin/cache-cleaner";
      User = "root";
    };
  };

  systemd.timers.cache-cleaner = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*:0/15";
      Persistent = true;
      RandomizedDelaySec = "30";
    };
  };

  fileSystems."/mnt/data" = {
    device = "/mnt/cache:/mnt/raid";
    fsType = "mergerfs";
    options = [
      "defaults"
      "moveonenospc=true"
      #"minfreespace=50G"
      "category.create=ff"
      "category.search=ff"
      "fsname=data"
    ];
    depends = ["/mnt/cache" "/mnt/raid"];
  };

  boot.kernelModules = ["fuse"];

  hardware.graphics = {
    enable = true;
  };

  services.xserver.videoDrivers = ["amdgpu"];

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };

    oci-containers.backend = "podman";

    quadlet = {
      enable = true;
      autoEscape = true;
      autoUpdate.enable = true;
    };

    containers.enable = true;

    containers.storage.settings = {
      storage = {
        driver = "overlay";
        runroot = "/run/containers/storage"; # tmpfs is fine for runtime
        graphroot = "/var/lib/containers/storage";
        options = {
          mount_program = "/run/current-system/sw/bin/fuse-overlayfs";
        };
      };
    };
  };

  # fileSystems."/mnt/media" = {
  #   device = "media";
  #   fsType = "virtiofs";
  #   options = [
  #     "rw"
  #     "relatime"
  #   ];
  # };
  # environment.etc."tmpfiles.d/media.conf".text = ''
  #   Z /mnt/media/torrents 0775 arr jellyfin -
  #   Z /mnt/media/media 0775 arr jellyfin -
  # '';
  # fileSystems."/mnt/music" = {
  #   device = "music";
  #   fsType = "virtiofs";
  #   options = [
  #     "rw"
  #     "relatime"
  #   ];
  # };
  # environment.etc."tmpfiles.d/music.conf".text = ''
  #   Z /mnt/music 0770 beets music -
  # '';
  # fileSystems."/mnt/share" = {
  #   device = "share";
  #   fsType = "virtiofs";
  #   options = [
  #     "rw"
  #     "relatime"
  #   ];
  # };
  # environment.etc."tmpfiles.d/share.conf".text = ''
  #   Z /mnt/share/syncthing/computer 0700 syncthing share -
  #   Z /mnt/share/syncthing/QGCube 0700 syncthing share -
  # '';
  # users.groups.share = {};
  # fileSystems."/mnt/immich" = {
  #   device = "immich";
  #   fsType = "virtiofs";
  #   options = [
  #     "rw"
  #     "relatime"
  #   ];
  # };
  # environment.etc."tmpfiles.d/immich.conf".text = ''
  #   Z /mnt/immich 0750 immich immich -
  # '';

  # fileSystems."/mnt/crypto" = {
  #   device = "crypto";
  #   fsType = "virtiofs";
  #   options = [
  #     "rw"
  #     "relatime"
  #   ];
  # };

  # environment.etc."tmpfiles.d/crypto.conf".text = ''
  #   Z /mnt/crypto 0700 bitcoin bitcoin -
  # '';

  # fileSystems."/persist" = {
  #   neededForBoot = true;
  # };

  networking.firewall.allowedTCPPorts = [
    22
  ];

  # fileSystems."/var/log".neededForBoot = true;
  # fileSystems."/var/lib/sops".neededForBoot = true;

  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
