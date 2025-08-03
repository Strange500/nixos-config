{config, ...}: {
  imports = [
    ./media
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