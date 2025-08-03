{
  inputs,
  config,
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

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    quadlet = {
      enable = true;
      autoEscape = true;
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
  fileSystems."/mnt/music" = {
    device = "music";
    fsType = "virtiofs";
    options = [
      "rw"
      "relatime"
    ];
  };
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
