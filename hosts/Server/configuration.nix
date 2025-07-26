{inputs, ...}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../modules/server
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  users.mutableUsers = false;

  fileSystems."/mnt/media" = {
    device = "media";
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

  networking.firewall = {
    enable = false;
  };

  boot = {
    initrd.availableKernelModules = ["virtiofs"];
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
