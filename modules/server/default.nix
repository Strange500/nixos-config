{...}: {
  imports = [
    ./media/jellyfin
    ./traefik
    ./traefik/migration.nix
    ./dashboard
    ./dns
    ./SSO
  ];    
}