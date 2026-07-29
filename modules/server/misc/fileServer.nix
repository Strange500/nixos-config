{
  config,
  pkgs,
  ...
}: {
  qgroget.services.file = {
    subdomain = "file";
    url = "http://127.0.0.1:8095";
    type = "public";
  };

  environment.etc."caddy/file-server.Caddyfile".text = ''
    :8095 {
      handle /img/* {
        root * /logo
        file_server
      }
      handle {
        root * /share
        file_server browse
      }
    }
  '';

  virtualisation.quadlet = {
    containers.file-server = {
      autoStart = true;
      containerConfig = {
        name = "file-server";
        image = "docker.io/caddy:alpine";
        publishPorts = ["8095:8095"];
        volumes = [
          "/etc/caddy/file-server.Caddyfile:/etc/caddy/Caddyfile:ro"
          "${config.logo.web}:/logo:ro"
          "/mnt/data/share/public:/share:ro"
        ];
      };
      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";
      };
    };
  };
}
