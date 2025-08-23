{
  config,
  lib,
  ...
}: let
  cfg = config.qgroget.server.permissions;
  
  # Helper function to create service users
  mkServiceUser = serviceName: serviceConfig: {
    name = serviceConfig.user;
    value = {
      isSystemUser = true;
      description = "User for ${serviceName} service";
      home = serviceConfig.homeDir;
      createHome = serviceConfig.createHome;
      group = serviceConfig.group;
      extraGroups = serviceConfig.extraGroups;
    };
  };
  
  # Helper function to create service groups
  mkServiceGroup = serviceName: serviceConfig: {
    name = serviceConfig.group;
    value = {};
  };
  
  # Helper function to create tmpfiles rules
  mkTmpfilesRule = serviceName: serviceConfig: 
    lib.optionals (serviceConfig.directories != []) (
      map (dir: 
        "${dir.type} ${dir.path} ${dir.mode} ${serviceConfig.user} ${serviceConfig.group} ${dir.age} ${dir.argument}"
      ) serviceConfig.directories
    );
    
  # Helper function to create SOPS secrets configuration
  mkSecretsConfig = serviceName: serviceConfig:
    lib.mapAttrs (secretName: secretConfig: {
      owner = serviceConfig.user;
      group = serviceConfig.group;
    } // secretConfig) serviceConfig.secrets;

in {
  options.qgroget.server.permissions = {
    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          user = lib.mkOption {
            type = lib.types.str;
            description = "System user for the service";
          };
          
          group = lib.mkOption {
            type = lib.types.str;
            description = "Primary group for the service";
          };
          
          extraGroups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Additional groups for the service user";
          };
          
          homeDir = lib.mkOption {
            type = lib.types.str;
            default = "/nonexistent";
            description = "Home directory for the service user";
          };
          
          createHome = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to create the home directory";
          };
          
          directories = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                path = lib.mkOption {
                  type = lib.types.str;
                  description = "Directory path";
                };
                
                mode = lib.mkOption {
                  type = lib.types.str;
                  default = "0755";
                  description = "Directory permissions";
                };
                
                type = lib.mkOption {
                  type = lib.types.str;
                  default = "d";
                  description = "tmpfiles.d type (d, Z, etc.)";
                };
                
                age = lib.mkOption {
                  type = lib.types.str;
                  default = "-";
                  description = "Age field for tmpfiles.d";
                };
                
                argument = lib.mkOption {
                  type = lib.types.str;
                  default = "-";
                  description = "Argument field for tmpfiles.d";
                };
              };
            });
            default = [];
            description = "Directories to manage for the service";
          };
          
          secrets = lib.mkOption {
            type = lib.types.attrsOf lib.types.attrs;
            default = {};
            description = "SOPS secrets configuration for the service";
          };
        };
      });
      default = {};
      description = "Service permission configurations";
    };
  };
  
  config = lib.mkIf (cfg.services != {}) {
    # Create users for all configured services
    users.users = lib.mkMerge (lib.mapAttrsToList mkServiceUser cfg.services);
    
    # Create groups for all configured services
    users.groups = lib.mkMerge (lib.mapAttrsToList mkServiceGroup cfg.services);
    
    # Create tmpfiles rules for all configured services
    systemd.tmpfiles.rules = lib.flatten (lib.mapAttrsToList mkTmpfilesRule cfg.services);
    
    # Configure SOPS secrets for all configured services
    sops.secrets = lib.mkMerge (lib.mapAttrsToList mkSecretsConfig cfg.services);
  };
}