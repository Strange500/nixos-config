{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../modules/server
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
    enable = true;
    useRoutingFeatures = "server";
  };

  environment.systemPackages = [
    pkgs.fuse-overlayfs
  ];

  boot.kernelModules = ["fuse"];

  # -----------------------------------------------------------------
  # ZFS global options (kernel modules, host-id, etc.)
  # -----------------------------------------------------------------
  boot.supportedFilesystems = ["zfs"];
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
}
