{config, ...}: let
  musicDir = "/mnt/music/media/beets"; # Adjust to your music directory
in {
  qgroget.services.navidrome = {
    name = "navidrome";
    url = "http://127.0.0.1:4533";
    type = "public";
  };

  virtualisation.quadlet = {

    containers.navidrome = {
      autoStart = true;
      
      containerConfig = {
        image = "docker.io/deluan/navidrome:latest";
                
        # Environment variables
        environments = {
          ND_SCANSCHEDULE = "@every 12h";
          ND_LOGLEVEL = "info";
          ND_SESSIONTIMEOUT = "24h";
          ND_SCANNER_GROUPALBUMRELEASES = "true";
          ND_BASEURL = "";
        };
        
        # Volume mounts
        volumes = [
          "${config.qgroget.server.containerDir}/navidrome/data:/data:Z"
          "${musicDir}:/music:ro,Z"
        ];
        
        # Port mapping
        publishPorts = ["4533:4533"];
        
      };

      serviceConfig = {
        Restart = "unless-stopped";
      };

      unitConfig = {
        Requires = ["network-online.target"];
        After = ["network-online.target"];
      };
    };
  };

}
