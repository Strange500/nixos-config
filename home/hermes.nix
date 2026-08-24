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
    username = "hermes";
    homeDirectory = "/home/hermes";
    stateVersion = "25.11";
    packages = [
      pkgs.git
      pkgs.gh
      pkgs.jq
    ];
  };

  # Git identity + gh CLI so the `hermes` agent can clone/commit over SSH.
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "hermes-agent";
        email = "hermes-agent@qgroget.com";
      };
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };

  programs.home-manager.enable = true;

  # Rootless service sandbox: `home-manager switch` touches only /home/hermes,
  # never system units or prod.
  virtualisation.quadlet.containers.echo-server = {
    autoStart = true;
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
    containerConfig = {
      image = "docker.io/mendhak/http-https-echo:31";
      publishPorts = ["127.0.0.1:12000:8080"];
      userns = "keep-id";
    };
  };

  # Second rootless demo service, declared the same way (copy of the working
  # echo-server on a different port). Proves a fresh service can be added,
  # rebuilt via home-manager, and exposed via the shared Traefik proxy without
  # touching system units.
  virtualisation.quadlet.containers.echo-server-2 = {
    autoStart = true;
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
    containerConfig = {
      image = "docker.io/mendhak/http-https-echo:31";
      publishPorts = ["127.0.0.1:12001:8080"];
      userns = "keep-id";
    };
  };

  # Declare the rootless services the same way the server declares its own
  # services: `qgroget.services.<name>` + subdomain/url. The traefik-router
  # module generates the full dynamic config (router + service + cert resolver)
  # and writes it under /var/lib/traefik/dynamic/, hot-reloaded by Traefik.
  qgroget.traefikRouter.enable = true;

  qgroget.services.echo = {
    subdomain = "echo";
    url = "http://127.0.0.1:12000";
    type = "public";
  };

  qgroget.services.echo2 = {
    subdomain = "echo2";
    url = "http://127.0.0.1:12001";
    type = "public";
  };
}