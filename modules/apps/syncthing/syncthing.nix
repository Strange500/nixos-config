{
  config,
  hostname,
  lib,
  ...
}: let
  cfg = config.qgroget.syncthing;

  clientDevices =
    lib.filterAttrs (
      name: device:
        lib.toLower device.name != lib.toLower hostname
    )
    cfg.settings.devices;

  clientFolders =
    lib.mapAttrs (
      name: folder:
        if folder ? client && folder.client.enable or false
        then {
          id = folder.client.id;
          ignorePerms = folder.client.ignorePerms;
          path = folder.client.path;
          type = folder.client.type;
          devices = folder.client.devices;
        }
        else null
    )
    cfg.settings.folders;

  filteredClientFolders = lib.filterAttrs (_: v: v != null) clientFolders;
in {
  sops = {
    secrets = {
      "syncthing/${hostname}/cert" = {};
      "syncthing/${hostname}/key" = {};
    };
  };

  services.syncthing = {
    enable = true;
    cert = "${config.sops.secrets."syncthing/${hostname}/cert".path}";
    key = "${config.sops.secrets."syncthing/${hostname}/key".path}";
    guiAddress = "127.0.0.1:8384";
    settings = {
      folders = filteredClientFolders;
      devices = clientDevices;
      options = cfg.settings.options;
    };
  };
}
