{
  config,
  hostname,
  lib,
  ...
}: let
  cfg = config.qgroget.syncthing;

  # keeps all devcices except the one named as this hostname
  serverDevices =
    lib.filterAttrs (
      name: device:
        lib.toLower device.name != lib.toLower hostname
    )
    cfg.settings.devices;

  # Build server folder configuration from options

  serverFolders =
    lib.mapAttrs (
      name: folder:
        if folder ? server && folder.server.enable or false
        then {
          id = folder.server.id;
          ignorePerms = folder.server.ignorePerms;
          path = folder.server.path;
          type = folder.server.type;
          devices = folder.server.devices;
        }
        else null
    )
    cfg.settings.folders;

  filteredServerFolders = lib.filterAttrs (_: v: v != null) serverFolders;
in {
  config = lib.mkIf (cfg.server) {
    sops.secrets = {
      "syncthing/${hostname}/cert" = {};
      "syncthing/${hostname}/key" = {};
    };

    qgroget.services.syncthing = {
      name = "syncthing";
      url = "http://${config.services.syncthing.guiAddress}";
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

    users.users.syncthing = {
      isSystemUser = true;
      group = "syncthing";
      home = "/var/lib/syncthing";
      createHome = true;
      extraGroups = ["share"];
    };
    users.groups.syncthing = {};

    services.syncthing = {
      enable = true;
      cert = "${config.sops.secrets."syncthing/${hostname}/cert".path}";
      key = "${config.sops.secrets."syncthing/${hostname}/key".path}";
      guiAddress = "0.0.0.0:8384";
      settings = {
        folders = filteredServerFolders;
        devices = serverDevices;
        options = cfg.settings.options;
      };
    };
  };
}
