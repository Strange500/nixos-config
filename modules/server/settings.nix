{
  lib,
  config,
  ...
}: {
  config = {
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
      seerr = {
        enable = true;
      };
      jellyfin = {
        enable = true;
      };
    };
  };
}
