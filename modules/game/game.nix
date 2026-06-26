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
        extraCompatPackages = [pkgs.proton-ge-bin];
        protontricks.enable = true;
      };
      gamemode.enable = true;
      appimage = {
        enable = true;
        binfmt = true;
      };
    };
    environment.systemPackages = with pkgs; [
      steam-rom-manager
      prismlauncher
      wine
      winetricks
      (import ./script.nix {inherit pkgs config;})
      (import ./steamImport.nix {inherit pkgs;})
      python3
      #      pkgs.proton-ge-custom
      protontricks
      lsfg-vk
      lsfg-vk-ui
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
