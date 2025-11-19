{
  lib,
  config,
  ...
}: {
  config = let
    secrets = [
      "server/jellyfin/user/admin/password"
      "server/jellyfin/user/strange/password"
    ];
  in {
    sops.secrets = builtins.listToAttrs (map (u: {
        name = u;
        value = {};
      })
      secrets);

    environment.persistence."/persist".directories = lib.concatLists [
      (lib.flatten (
        lib.mapAttrsToList
        (
          name: service:
            lib.optionals (service.persistedData != null) [service.persistedData]
        )
        (config.qgroget.services or {})
      ))
      ["${config.qgroget.server.containerDir}" "/var/lib/postgresql" "/var/lib/containers"]
    ];

    qgroget.server = {
      jellyseerr = {
        enable = true;
      };
      jellyfin = {
        enable = true;
        users = {
          admin = {
            mutable = false;
            hashedPasswordSecret = config.sops.secrets."server/jellyfin/user/admin/password".path;
            permissions = {isAdministrator = true;};
          };
          strange = {
            mutable = true;
            hashedPasswordSecret = config.sops.secrets."server/jellyfin/user/strange/password".path;
            permissions = {
              isAdministrator = false;
              enableAllFolders = false;
            };
          };
        };
      };
    };
  };
}
