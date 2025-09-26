{
  inputs,
  config,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.jovian-nixos.nixosModules.default
    ../../modules/system/tpm/tpm.nix
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  users.mutableUsers = false;

  services.crowdsec.enable = true;
  jovian = {
    steam = {
      enable = true;
      user = config.qgroget.user.username;
      autoStart = true;
      desktopSession = "plasmax11";
    };

    hardware = {
      has = {
        amd = {
          gpu = true;
        };
      };
    };
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility"; # For systems with AMD GPUs
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
