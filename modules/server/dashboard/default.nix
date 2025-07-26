{config,...}: {
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        unraid = {
          rule = "Host(`unraid.${config.qgroget.server.domain}`)";
          entryPoints = ["websecure"];
          service = "unraid";
          tls = {
            certResolver = if config.qgroget.server.test.enable then "staging" else "production";
          };
        };
      };

      services = {
        unraid = {
          loadBalancer = {
            servers = [
              {url = "http://192.168.0.28";}
            ];
          };
        };
      };
    };
  };
}