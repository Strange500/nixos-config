{config, ...}: {
  imports = [
    ./media
    ./arrs
    ./downloaders
    ./traefik
    ./traefik/migration.nix
    ./dashboard
    ./password-manager
    ./dns
    ./SSO
  ];   

  environment.persistence."/persist".directories = [
    "${config.qgroget.server.containerDir}"
  ]; 
}