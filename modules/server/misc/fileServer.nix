{...}: {
  qgroget.services.file = {
    name = "file";
    url = "http://127.0.0.1:8095";
    type = "public";
  };

  virtualisation.quadlet = {
    containers.file-server = {
      autoStart = true;
      containerConfig = {
        name = "file-server";
        image = "halverneus/static-file-server:latest";
        publishPorts = ["8095:8080"];
        volumes = [
          "/mnt/share/file_serv:/web:ro"
        ];
      };
      serviceConfig = {
        Restart = "unless-stopped";
      };
    };
  };
}
