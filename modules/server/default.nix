{config, ...}: {
  imports = [
    ./media/jellyfin
    ./media/music
    ./traefik
    ./traefik/migration.nix
    ./dashboard
    ./dns
    ./SSO
  ];   

  environment.persistence."/persist".directories = [
    "${config.qgroget.server.containerDir}"
  ]; 
}