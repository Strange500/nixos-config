{
  config,
  lib,
  ...
}: {
  imports = [
    ./options.nix
    ./settings.nix
    ./media
    ./arrs
    # ./security
    ./downloaders
    ./traefik
    ./dashboard
    ./password-manager
    ./dns
    ./SSO
    ./backup
    ./misc
    # ./homeAssistant
  ];

  config = {
    # Validation: Ensure all enabled services have required fields
    assertions = lib.flatten (lib.mapAttrsToList (
      serviceName: serviceConfig: let
        isEnabled = serviceConfig.enable or false;
        hasDomain = serviceConfig.domain or null != null;
        hasDataDir = serviceConfig.dataDir or null != null;
        missingFields =
          []
          ++ (lib.optional (!hasDomain) "domain")
          ++ (lib.optional (!hasDataDir) "dataDir");
        missingFieldsStr = lib.concatStringsSep ", " missingFields;
      in
        if isEnabled && missingFields != []
        then [
          {
            assertion = false;
            message = ''
              Service '${serviceName}' is enabled but missing required field(s): ${missingFieldsStr}

              Configuration Error:
              When qgroget.serviceModules.${serviceName}.enable = true, you must provide:
              ${lib.optionalString (!hasDomain) "  - domain (string): Domain name for the service (e.g., \"${serviceName}.example.com\")"}
              ${lib.optionalString (!hasDataDir) "  - dataDir (string): Data directory path for persistent data (e.g., \"/var/lib/${serviceName}\")"}

              Example fix:
              qgroget.serviceModules.${serviceName} = {
                enable = true;
              ${lib.optionalString (!hasDomain) "  domain = \"${serviceName}.example.com\";"}
              ${lib.optionalString (!hasDataDir) "  dataDir = \"/var/lib/${serviceName}\";"}
              };
            '';
          }
        ]
        else []
    ) (config.qgroget.serviceModules or {}));
  };
}
