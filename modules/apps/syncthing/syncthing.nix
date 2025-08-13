{
  config,
  hostname,
  lib,
  ...
}: let
  cfg = config.qgroget.syncthing;

  # Extract client devices (devices that are NOT this client)
  clientDevices =
    lib.filterAttrs (
      name: device:
        device.id != cfg.settings.devices.computer.id
    )
    cfg.settings.devices;

  # Build client folder configuration from options
  clientFolders =
    lib.mapAttrs' (
      name: folderCfg: let
        # Map folder names to enable conditions
        enableCondition =
          if name == "Documents"
          then config.qgroget.nixos.apps.sync.desktop.enable
          else if name == "QGCube"
          then config.qgroget.nixos.apps.sync.game.enable
          else true; # Default to enabled for other folders
      in
        lib.nameValuePair name (lib.mkIf (folderCfg.enable && folderCfg.client.enable && enableCondition) {
          inherit (folderCfg) id ignorePerms;
          path = folderCfg.client.path;
          type = folderCfg.client.type;
          devices = map (deviceName: cfg.settings.devices.${deviceName}.id) folderCfg.client.devices;
        })
    )
    cfg.settings.folders;
in {
  sops.secrets = {
    "syncthing/${hostname}/cert" = {};
    "syncthing/${hostname}/key" = {};
  };

  services.syncthing = {
    enable = true;
    cert = "${config.sops.secrets."syncthing/${hostname}/cert".path}";
    key = "${config.sops.secrets."syncthing/${hostname}/key".path}";
    settings = {
      folders = clientFolders;
      devices = clientDevices;
      options = cfg.settings.options;
    };
  };
}
