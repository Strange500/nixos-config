{
  inputs,
  config,
  pkgs,
  ...
}: let
  # Create a custom Kodi Wayland session package
  kodiSessionPackage =
    pkgs.runCommand "kodi-cage-session" {
      passthru.providedSessions = ["kodi-cage"];
    } ''
          mkdir -p $out/share/wayland-sessions

          cat > $out/share/wayland-sessions/kodi-cage.desktop <<EOF
      [Desktop Entry]
      Name=Kodi (Cage/Wayland)
      Comment=Kodi Media Center on Wayland
      Exec=${pkgs.cage}/bin/cage -- ${pkgs.kodi-wayland.withPackages (p: [
        p.inputstream-adaptive
        p.jellycon
        p.youtube
      ])}/bin/kodi-standalone
      Type=Application
      DesktopNames=kodi-cage
      EOF
    '';
in {
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

  networking.interfaces.enp3s0.wakeOnLan.enable = true;

  services.displayManager.sessionPackages = [kodiSessionPackage];

  users.users.kodi = {
    isNormalUser = true;
    extraGroups = ["video" "audio" "input" "render"];
  };

  jovian = {
    steam = {
      enable = true;
      user = config.qgroget.user.username;
      autoStart = true;
      desktopSession = "kodi-cage";
    };

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
