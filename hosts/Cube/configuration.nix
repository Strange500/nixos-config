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
    inputs.jovian-nixos.nixosModules.default
    ../../modules/system/tpm/tpm.nix
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  services.xserver.enable = true;

  jovian = {
    steam = {
      enable = true;
      user = config.qgroget.user.username;
      autoStart = true;
      desktopSession = "gnome";
    };
    # needs touch ~/.steam/steam/.cef-enable-remote-debugging to work
    decky-loader = {
      enable = true;
      package = pkgs.decky-loader-prerelease;
      extraPackages = with pkgs; [
        coreutils
        bash
        systemd
        python3
      ];
    };
    hardware.has.amd.gpu = true;
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
