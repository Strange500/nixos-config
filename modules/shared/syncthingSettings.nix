# options.nix - Syncthing options definition
{
  config,
  lib,
  ...
}: let
  cfg = config.qgroget.syncthing;
in {
  options = {
    qgroget.syncthing = {
      enable = lib.mkEnableOption "Enable Syncthing";

      server = lib.mkEnableOption "Enable server mode";

      settings = {
        devices = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              id = lib.mkOption {
                type = lib.types.str;
                description = "Device ID";
              };
              name = lib.mkOption {
                type = lib.types.str;
                description = "Device name";
              };
              addresses = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = ["dynamic"];
                description = "Device addresses";
              };
            };
          });
          default = {};
          description = "Syncthing devices";
        };

        folders = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              id = lib.mkOption {
                type = lib.types.str;
                description = "Folder ID";
              };

              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable this folder";
              };

              ignorePerms = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Ignore permissions";
              };

              client = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Enable on client";
                };

                path = lib.mkOption {
                  type = lib.types.str;
                  description = "Client folder path";
                };

                type = lib.mkOption {
                  type = lib.types.enum ["sendreceive" "sendonly" "receiveonly"];
                  default = "sendreceive";
                  description = "Client folder type";
                };

                devices = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Client devices to sync with";
                };
              };

              server = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Enable on server";
                };

                path = lib.mkOption {
                  type = lib.types.str;
                  description = "Server folder path";
                };

                type = lib.mkOption {
                  type = lib.types.enum ["sendreceive" "sendonly" "receiveonly"];
                  default = "sendreceive";
                  description = "Server folder type";
                };

                devices = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Server devices to sync with";
                };
              };
            };
          });
          default = {};
          description = "Syncthing folders configuration";
        };

        options = lib.mkOption {
          type = lib.types.submodule {
            options = {
              upnpEnabled = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable UPnP";
              };

              localAnnounceEnabled = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable local announce";
              };

              globalAnnounceEnabled = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable global announce";
              };

              relaysEnabled = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable relays";
              };

              urAccepted = lib.mkOption {
                type = lib.types.int;
                default = -1;
                description = "Usage reporting acceptance";
              };
            };
          };
          default = {};
          description = "Syncthing options";
        };

        stignore = lib.mkOption {
          type = lib.types.str;
          default = ''
            .*
            *.tmp
            *.log
            *~
            *.swp
            .DS_Store
            wallpaper
            nixos'';
          description = "Syncthing ignore patterns";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Example configuration
    qgroget.syncthing.settings = lib.mkDefault {
      devices = {
        computer = {
          id = "MIEGPSQ-YF5VPLB-JFCL4IO-ANCQE5V-3ED4YE2-JARMEHX-63N7N4I-UGDLPAT";
          name = "Computer";
          addresses = ["dynamic"];
        };

        server = {
          id = "THPSKZ7-45G7YFY-P566CM4-O5R3WMV-IVGFIXS-QPOP6VH-LIK7MGR-5G63BAY";
          name = "Server";
          addresses = ["dynamic"];
        };
      };

      folders = {
        Documents = {
          id = "rglxv-6cyvw";
          ignorePerms = false;

          client = {
            enable = true;
            path = "${config.home.homeDirectory}/Documents";
            type = "sendreceive";
            devices = ["server"];
          };

          server = {
            enable = true;
            path = "/mnt/share/syncthing/computer/Documents";
            type = "sendreceive";
            devices = ["computer"];
          };
        };

        QGCube = {
          id = "pqmdn-esnyq";
          ignorePerms = false;

          client = {
            enable = true;
            path = "${config.home.homeDirectory}/gameSync";
            type = "receiveonly";
            devices = ["server"];
          };

          server = {
            enable = true;
            path = "/mnt/share/syncthing/QGCube";
            type = "sendonly";
            devices = ["computer"];
          };
        };
      };

      options = {
        upnpEnabled = true;
        localAnnounceEnabled = false;
        globalAnnounceEnabled = true;
        relaysEnabled = true;
        urAccepted = -1;
      };
    };
  };
}
