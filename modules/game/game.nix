{
  pkgs,
  config,
  lib,
  ...
}: let
  autoInstallScript = pkgs.writeShellScriptBin "auto-install" ''

  '';
in {
  config = lib.mkIf (config.qgroget.nixos.gaming) {
    programs = {
      steam = {
        enable = true;
        package = pkgs.steam;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
        localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
        extraCompatPackages = [pkgs.proton-ge-bin];
        protontricks.enable = true;
      };
      gamemode.enable = true;
      appimage = {
        enable = true;
        binfmt = true;
      };
    };
    environment.systemPackages =
      [
        pkgs.steam-rom-manager
        pkgs.prismlauncher
        pkgs.wine
        pkgs.winetricks
        (import ./script.nix {inherit pkgs config;})
        pkgs.python3
        pkgs.proton-ge-custom
        pkgs.protontricks
      ]
      ++ lib.optionals config.qgroget.nixos.vr [
        pkgs.opencomposite
        pkgs.wlx-overlay-s
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
      autoStart = true;
      highPriority = true;
      steam.importOXRRuntimes = true;
    };

    services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
      motherboard = "amd";
    };
  };
}
