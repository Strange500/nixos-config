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

  environment.systemPackages = [
    pkgs.fuse-overlayfs
  ];

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

  fileSystems."/mnt/media" = {
    device = "media";
    fsType = "virtiofs";
    options = [
      "rw"
      "relatime"
    ];
  };
  environment.etc."tmpfiles.d/media.conf".text = ''
    Z /mnt/media/torrents 0775 arr jellyfin -
    Z /mnt/media/media 0775 arr jellyfin -
  '';
  fileSystems."/mnt/music" = {
    device = "music";
    fsType = "virtiofs";
    options = [
      "rw"
      "relatime"
    ];
  };
  environment.etc."tmpfiles.d/music.conf".text = ''
    Z /mnt/music 0770 beets music -
  '';
  fileSystems."/mnt/share" = {
    device = "share";
    fsType = "virtiofs";
    options = [
      "rw"
      "relatime"
    ];
  };
  environment.etc."tmpfiles.d/share.conf".text = ''
    Z /mnt/share/syncthing/computer 0700 syncthing share -
    Z /mnt/share/syncthing/QGCube 0700 syncthing share -
  '';
  users.groups.share = {};
  fileSystems."/mnt/immich" = {
    device = "immich";
    fsType = "virtiofs";
    options = [
      "rw"
      "relatime"
    ];
  };
  environment.etc."tmpfiles.d/immich.conf".text = ''
    Z /mnt/immich 0750 immich immich -
  '';

  fileSystems."/mnt/crypto" = {
    device = "crypto";
    fsType = "virtiofs";
    options = [
      "rw"
      "relatime"
    ];
  };

  users.groups.crypto = {};
  users.users.crypto = {
    group = "crypto";
    home = "/mnt/crypto";
    description = "Crypto Service User";
  };

  environment.etc."tmpfiles.d/crypto.conf".text = ''
    Z /mnt/crypto 0700 crypto crypto -
  '';

  fileSystems."/persist" = {
    neededForBoot = true;
    device = "persist";
    fsType = "virtiofs";
    options = [
      "rw"
      "relatime"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    22
  ];

  fileSystems."/var/log".neededForBoot = true;
  fileSystems."/var/lib/sops".neededForBoot = true;

  boot = {
    initrd.availableKernelModules = ["virtiofs"];
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
