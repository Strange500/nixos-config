{
  config,
  hostname,
  lib,
  ...
}: let
  cfg = config.qgroget.syncthing;

  # Extract server devices (devices that are NOT this server)
  serverDevices =
    lib.filterAttrs (
      _name: device:
        device.id != cfg.settings.devices.server.id
    )
    cfg.settings.devices;

  # Build server folder configuration from options
  serverFolders =
    lib.mapAttrs' (
      name: folderCfg:
        lib.nameValuePair name (lib.mkIf (folderCfg.enable && folderCfg.server.enable) {
          inherit (folderCfg) id ignorePerms;
          path = folderCfg.server.path;
          type = folderCfg.server.type;
          devices = map (deviceName: cfg.settings.devices.${deviceName}.id) folderCfg.server.devices;
        })
    )
    cfg.settings.folders;
in {
  config = lib.mkIf (cfg.enable && cfg.server) {
    sops.secrets = {
      "syncthing/${hostname}/cert" = {};
      "syncthing/${hostname}/key" = {};
    };

    qgroget.services.syncthing = {
      name = "syncthing";
      url = "http://127.0.0.1:8384";
      type = "private";
    };

    fileSystems = {
      "/mnt/share/syncthing/computer" = {
        device = "syncthing-computer";
        fsType = "virtiofs";
        options = [
          "rw"
          "relatime"
        ];
      };
      "/mnt/share/syncthing/QGCube" = {
        device = "syncthing-qgcube";
        fsType = "virtiofs";
        options = [
          "rw"
          "relatime"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /mnt/share/syncthing/computer - - - - syncthing syncthing 0700"
      "d /mnt/share/syncthing/QGCube - - - - syncthing syncthing 0700"
      "Z /mnt/share/syncthing/computer - - - - syncthing syncthing 0700"
      "Z /mnt/share/syncthing/QGCube - - - - syncthing syncthing 0700"
    ];

    services.syncthing = {
      enable = true;
      cert = "${config.sops.secrets."syncthing/${hostname}/cert".path}";
      key = "${config.sops.secrets."syncthing/${hostname}/key".path}";
      settings = {
        folders = serverFolders;
        devices = serverDevices;
        options = cfg.settings.options;
      };
    };
  };
}
