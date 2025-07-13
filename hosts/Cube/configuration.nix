{
  inputs,
  lib,
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
  ];

  users.mutableUsers = false;

  jovian.steamos.useSteamOSConfig = true;

  jovian = {
    steam = {
      enable = true;
      user = config.qgroget.user.username;
      autoStart = true;
      desktopSession = "plasma";
      updater.splash = "bgrt";
    };
    decky-loader = {
      enable = true;
      user = config.qgroget.user.username;
    };
    hardware = {
      amd.gpu = {
        enableEarlyModesetting = true;
        enableBacklightControl = true;
      };
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
