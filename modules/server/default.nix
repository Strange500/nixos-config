{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./media
    ./arrs
    ./security
    ./downloaders
    ./traefik
    ./traefik/migration.nix
    ./dashboard
    ./password-manager
    ./dns
    ./SSO
  ];

  # tmpfile rule to create the log directory

  config = {
    
    # Create 'logs' group
    users.groups.logs = {};

    # Add your users to the right groups
    users.users.strange.extraGroups = ["logs" "jellyfin"];
    users.users.crowdsec.extraGroups = ["systemd-journal" "logs" "jellyfin"];

    # Configure tmpfiles for logs directory
    environment.etc."tmpfiles.d/qgroget.conf".text = ''
      # Create the main logs directory with correct group and setgid
      d ${config.qgroget.logDir} 2775 root logs - -

      # Set default ACLs so new files/dirs inherit group permissions
      a+ ${config.qgroget.logDir} - - - - \
        d:g:logs:r-x,d:g:logs:r--,g:logs:r-x,g:logs:r--

      # Recursively fix existing permissions
      Z ${config.qgroget.logDir} - - logs - -
    '';
  };

  options.qgroget = {
    logDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/log/qgroget";
      description = "Directory where QGroget logs are stored.";
    };
    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Service name for subdomain";
          };
          url = lib.mkOption {
            type = lib.types.str;
            description = "Backend URL";
          };
          type = lib.mkOption {
            type = lib.types.enum ["private" "public"];
            default = "private";
            description = "either 'private' or 'public'. 'private' means that the service is only accessible from the local network, while 'public' means it is accessible from the internet.";
          };
          middlewares = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of middlewares to apply to the service.";
          };
          logPath = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Path to the log file for the service.";
          };
          journalctl = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "If true, the service will be logged using journalctl.";
          };
          unitName = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "The name of the systemd unit for the service, used for journalctl filtering.";
          };
        };
      });
      default = {};
      description = "QGroget services to be managed";
    };
  };

  config = {
    environment.persistence."/persist".directories = [
      "${config.qgroget.server.containerDir}"
    ];
  };
}
