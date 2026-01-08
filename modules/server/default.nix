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
        hasRequiredFields =
          (serviceConfig.domain or null != null)
          && (serviceConfig.dataDir or null != null);
      in
        if isEnabled && !hasRequiredFields
        then [
          {
            assertion = false;
            message = ''
              Service '${serviceName}' is enabled but missing required fields.

              Configuration Error:
              When qgroget.serviceModules.${serviceName}.enable = true, you must provide:
              - domain (string): Domain name for the service
              - dataDir (string): Data directory path for persistent data

              Example fix:
              qgroget.serviceModules.${serviceName} = {
                enable = true;
                domain = "myservice.example.com";
                dataDir = "/var/lib/${serviceName}";
              };
            '';
          }
        ]
        else []
    ) (config.qgroget.serviceModules or {}));
  };
}
