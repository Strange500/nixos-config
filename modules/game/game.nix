{
  pkgs,
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.qgroget.nixos.gaming) {
    programs = {
      steam = {
        enable = true;
        package = pkgs.steam;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
        localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
      };
      gamemode.enable = true;
      appimage = {
        enable = true;
        binfmt = true;
      };
    };
    environment.systemPackages = with pkgs;
      [
        protontricks
        steam-rom-manager
      ]
      ++ lib.optionals config.qgroget.nixos.vr [
        opencomposite
        wlx-overlay-s
      ];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    services.xserver.videoDrivers = ["amdgpu"];

    programs.git = {
      enable = true;
      lfs.enable = true;
    };

    systemd.user.services.monado.environment = lib.mkIf config.qgroget.nixos.vr {
      STEAMVR_LH_ENABLE = "1";
      XRT_COMPOSITOR_COMPUTE = "1";
      HAND_TRACKING_ENABLE = "1";
    };

    services.wivrn = lib.mkIf config.qgroget.nixos.vr {
      enable = true;
      openFirewall = true;
      defaultRuntime = true;
      autoStart = false;
    };

    services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
      motherboard = "amd";
    };
  };
}
