{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./modules/traefik-router.nix
    inputs.quadlet-nix.homeManagerModules.quadlet
  ];

  home = {
    username = "misc";
    homeDirectory = "/home/misc";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;

  # Rootless portfolio: nginx serves the same static Next.js export that used
  # to be served by the rootful system nginx, but now as an isolated quadlet
  # container under the `misc` user. `home-manager switch --flake .#misc`
  # touches only /home/misc, never system units or prod.
  virtualisation.quadlet.containers.portfolio = {
    autoStart = true;
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
    containerConfig = {
      image = "docker.io/library/nginx:alpine";
      publishPorts = ["127.0.0.1:3001:80"];
      volumes = [
        "${inputs.portfolio.packages.${pkgs.system}.default}:/usr/share/nginx/html:ro"
      ];
    };
  };

  # Expose behind the central Traefik proxy, identical to the old rootful route
  # (portfolio.qgroget.com -> 127.0.0.1:3001, public, no googlenoindex).
  qgroget.traefikRouter.enable = true;
  qgroget.services.portfolio = {
    subdomain = "portfolio";
    url = "http://127.0.0.1:3001";
    type = "public";
  };
}
