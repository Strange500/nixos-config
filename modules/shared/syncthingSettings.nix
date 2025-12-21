# options.nix - Syncthing options definition
{
  config,
  lib,
  ...
}: {
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
              client = {
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

  config = {
    qgroget.syncthing.server = true;
    qgroget.syncthing.settings = lib.mkDefault {
      devices = {
        computer = {
          id = "MIEGPSQ-YF5VPLB-JFCL4IO-ANCQE5V-3ED4YE2-JARMEHX-63N7N4I-UGDLPAT";
          name = "computer";
          addresses = ["dynamic"];
        };

        cube = {
          id = "CTNRWX7-SVJNCAG-Q7TFCYP-QRUQ2JJ-2LZMVLU-HMF2GWA-2MKTZZN-FO5PBQQ";
          name = "cube";
          addresses = ["dynamic"];
        };

        server = {
          id = "KRX6LMH-4XURSRV-HBBBYJR-FN3VGP3-BIKXM3I-MANABJO-6ACA26Z-JW5WOA3";
          name = "server";
          addresses = ["dynamic"];
        };
      };

      folders = {
        Documents = let
          id = "rglxv-6cyvw";
          ignorePerms = false;
        in {
          client = {
            id = id;
            ignorePerms = ignorePerms;
            enable = true;
            path = "${config.home.homeDirectory}/Documents";
            type = "sendreceive";
            devices = ["server"];
          };

          server = {
            id = id;
            ignorePerms = ignorePerms;
            enable = true;
            path = "/mnt/data/Sync/Documents";
            type = "sendreceive";
            devices = ["computer"];
          };
        };

        QGCube = let
          id = "pqmdn-esnyq";
          ignorePerms = false;
        in {
          client = {
            id = id;
            ignorePerms = ignorePerms;
            enable = true;
            path = "${config.home.homeDirectory}/gameSync";
            type = "receiveonly";
            devices = ["server"];
          };

          server = {
            id = id;
            ignorePerms = ignorePerms;
            enable = true;
            path = "/mnt/data/Sync/gameSync";
            type = "sendonly";
            devices = ["cube"];
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
