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
      };
      gamemode.enable = true;
      appimage = {
        enable = true;
        binfmt = true;
      };
    };
    environment.systemPackages = with pkgs; [
      protontricks
      steam-rom-manager
    ];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    services.xserver.videoDrivers = ["amdgpu"];

    services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
      motherboard = "amd";
    };
  };
}
