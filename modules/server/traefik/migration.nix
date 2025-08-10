{...}:let
  server = "http://192.168.0.28";
  in {
  qgroget.services = {
    file = {
      name = "file";
      url = "${server}:8095";
      type = "public";
    };
    list = {
      name = "list";
      url = "${server}:5244";
      type = "private";
    };
    portfolio = {
      name = "portfolio";
      url = "${server}:3000";
      type = "public";
    };
    # The Traefik Network
      # Don't forget to replace 'obsidian-livesync.example.org' with your own domain
      # - "traefik.http.routers.obsidian-livesync.rule=Host(`obsidian.qgroget.com`)"
      # # The 'websecure' entryPoint is basically your HTTPS entrypoint. Check the next code snippet if you are encountering problems only; you probably have a working traefik configuration if this is not your first container you are reverse proxying.
      # - "traefik.http.routers.obsidian-livesync.entrypoints=websecure"
      # - "traefik.http.routers.obsidian-livesync.service=obsidian-livesync"
      # - "traefik.http.services.obsidian-livesync.loadbalancer.server.port=5984"
      # - "traefik.http.routers.obsidian-livesync.tls=true"
      # # Replace the string 'letsencrypt' with your own certificate resolver
      # - "traefik.http.routers.obsidian-livesync.tls.certresolver=production"
      # - "traefik.http.routers.obsidian-livesync.middlewares=obsidiancors"
      # # The part needed for CORS to work on Traefik 2.x starts here
      # - "traefik.http.middlewares.obsidiancors.headers.accesscontrolallowmethods=GET,PUT,POST,HEAD,DELETE"
      # - "traefik.http.middlewares.obsidiancors.headers.accesscontrolallowheaders=accept,authorization,content-type,origin,referer"
      # - "traefik.http.middlewares.obsidiancors.headers.accesscontrolalloworiginlist=app://obsidian.md,capacitor://localhost,http://localhost,https://obsidian.qgroget.com"
      # - "traefik.http.middlewares.obsidiancors.headers.accesscontrolmaxage=3600"
      # - "traefik.http.middlewares.obsidiancors.headers.addvaryheader=true"
      # - "traefik.http.middlewares.obsidiancors.headers.accessControlAllowCredentials=true"
    obsidian = {
      name = "obsidian";
      url = "${server}:5984";
      type = "public";
    };
    # syncthing = {
    #   name = "syncthing";
    #   url = "${server}:8384";
    #   type = "public";
    # };
  };
}