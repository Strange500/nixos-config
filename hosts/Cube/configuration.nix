{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/profiles/base.nix
    ../../modules/profiles/desktop.nix
    ../../modules/profiles/gaming.nix
    ./settings.nix
    ../../modules/system/tpm/tpm.nix
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  services.xserver.enable = true;

  networking.interfaces.enp3s0.wakeOnLan.enable = true;

  sops.secrets = {
    "ssh/private" = {
      owner = "game-installer";
      # group = "game-installer";
      # mode = "0600";
    };
  };

  services.game-installer = {
    enable = true;
    user = "game-installer";
    openFirewall = true;
    localInstallBase = "/data/games";
    environment = {
      SSH_HOST = "192.168.0.28";
      SSH_PORT = "22";
      SSH_USERNAME = "strange";
      SSH_PRIVATE_KEY_PATH = config.sops.secrets."ssh/private".path;
      PUBLIC_HOST = "192.168.0.138";
      PUBLIC_PROTOCOL = "http";
      WINDOWS_RUNTIME = "proton";
    };
  };

  # allow everyone to write under /data
  systemd.tmpfiles.rules = [
    "d /data 0777 root root -"
    "d /data/games 0777 root root -"
  ];

  systemd.services.game-installer.serviceConfig.ReadWritePaths = [
    "/data"
  ];

  systemd.services.game-installer.serviceConfig.UMask = lib.mkForce "0000";

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

  # --- Gaming tuning (Cube-specific) ---
  # Low-latency desktop kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.kernelParams = [
    "amd_pstate=active" # prefer amd-pstate EPP governor for lower latency
    "amdgpu.ppfeaturemask=0xffffffff" # unlock CoreCtrl undervolt/OC/fan control
  ];

  # esync/fsync (Proton/Wine) needs a much higher map count
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

  environment.systemPackages = with pkgs; [
    mangohud # FPS overlay + framerate limiter
    corectrl # AMD GPU/CPU tuning GUI
    heroic # Epic/GOG launcher
    lutris # non-Steam launcher
    gamescope # per-game compositor (HDR, upscale, nested)
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = lib.mkForce ["nodev"];
  };
}
