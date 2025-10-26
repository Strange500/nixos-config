{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = {
    containerDir = "${config.qgroget.server.containerDir}";
    podName = "crypto";

    ports = {
      rotki = 8078;
    };

    containers = {
      rotki = "rotki";
    };
  };

  images = {
    rotki = "rotki/rotki:latest";
  };

  inherit (config.virtualisation.quadlet) pods;
in {
  qgroget.services = {
    rotki = {
      name = "rotki";
      url = "http://127.0.0.1:${toString cfg.ports.rotki}";
      type = "private";
      middlewares = ["SSO"];
    };
  };

  services.authelia.instances.qgroget.settings.access_control.rules = lib.mkAfter [
    {
      domain = "rotki.${config.qgroget.server.domain}";
      policy = "two_factor";
      subject = [
        "group:admin"
      ];
    }
  ];

  qgroget.backups.arr = {
    paths = [
      "${cfg.containerDir}/rotki/data"
    ];
    systemdUnits = [
      "${cfg.podName}-pod.service"
    ];
  };

  environment.persistence."/persist".directories = [
    "${cfg.containerDir}/rotki/data"
  ];

  virtualisation.quadlet = {
    pods.${cfg.podName} = {
      autoStart = true;
      podConfig = {
        name = cfg.podName;
        publishPorts = [
          # expose Rotki Web UI
          "${toString cfg.ports.rotki}:80"
        ];
      };
      unitConfig = {
        Requires = ["network-online.target"];
        After = ["network-online.target"];
      };
    };

    containers = {
      rotki = {
        autoStart = true;
        containerConfig = {
          name = cfg.containers.rotki;
          pod = pods.${cfg.podName}.ref;
          image = images.rotki;
          volumes = [
            "${cfg.containerDir}/rotki/data:/data:Z"
          ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };
  };
}
