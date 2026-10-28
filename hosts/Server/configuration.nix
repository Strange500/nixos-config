{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/profiles/base.nix
    ../../modules/profiles/server.nix
    ./settings.nix
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

  services.tailscale = {
    useRoutingFeatures = lib.mkForce "server";
  };

  environment.systemPackages = [
    pkgs.fuse-overlayfs
  ];

  boot.kernelModules = ["fuse"];

  # -----------------------------------------------------------------
  # ZFS global options (kernel modules, host-id, etc.)
  # -----------------------------------------------------------------
  boot.supportedFilesystems = ["zfs"];
  # Silence the 26.11 warning without changing current behaviour (the default
  # is `true` today; it becomes `false` in 26.11). Kept explicit to prevent
  # a silent behavioural change on that bump.
  boot.zfs.forceImportRoot = true;
  networking.hostId = "8425e3c1"; # <-- generate with `head -c4 /dev/urandom | od -An -t u4`
  services.zfs = {
    trim.enable = true;
    autoSnapshot.enable = false; # we manage our own blank snapshot
  };

  boot.kernelPackages = pkgs.linuxPackages_6_12; # newest ZFS
  boot.initrd.kernelModules = ["zfs" "xfs" "nvme"];

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

    # Allow short-name resolution (e.g. `podman run hello-world`) so that
    # rootless users can pull & run images without fully-qualified names.
    # Declared via `.settings` (`.search`/`.insecure`/`.block` are deprecated).
    containers.registries.settings = {
      search = [ "docker.io" ];
    };

    # Podman 6.0: base `settings` now applies to BOTH rootful and rootless.
    # graphroot/runroot must therefore be scoped per-mode, or rootless would
    # be pointed at root-only paths (/var/lib, /run) and break.
    containers.storage.settings = {
      storage = {
        driver = "overlay";
        options = {
          mount_program = "/run/current-system/sw/bin/fuse-overlayfs";
        };
      };
    };

    # Keep the privileged store paths rootful-only (same values as before).
    # Rootless keeps its defaults (~/.local/share/containers/storage).
    containers.storage.rootful.settings.storage = {
      runroot = "/run/containers/storage"; # tmpfs is fine for runtime
      graphroot = "/var/lib/containers/storage";
    };
  };

  networking.firewall.allowedTCPPorts = [
    22
  ];

  nixpkgs.config.allowBroken = true;

  # fileSystems."/var/log".neededForBoot = true;
  # fileSystems."/var/lib/sops".neededForBoot = true;

  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true; # Often helps with NVMe/SATA swaps

    # For UEFI, we do NOT list the disk ID here.
    devices = ["nodev"];

    # Ensure this matches the mirrors if you are doing mirrored booting,
    # but for now, "nodev" is sufficient for a single UEFI bootloader.
  };

  systemd.services."systemd-tmpfiles-resetup" = {
    serviceConfig = {
      RemainAfterExit = lib.mkForce false;
    };
  };
}
