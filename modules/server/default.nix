{...}: {
  imports = [
    ./options.nix
    ./settings.nix
    ./media
    ./arrs
    ./security
    ./downloaders
    ./traefik
    ./dashboard
    ./password-manager
    ./dns
    ./SSO
    ./backup
    ./misc
    ./crypto
    ./homeAssistant
  ];
}
