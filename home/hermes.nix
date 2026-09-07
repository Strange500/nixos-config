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

  # Declare the rootless `echo-server` the same way the server declares its own
  # services: `qgroget.services.<name>` + subdomain/url. The traefik-router
  # module generates the full dynamic config (router + service + cert resolver)
  # and writes it under /var/lib/traefik/dynamic/, hot-reloaded by Traefik.
  qgroget.traefikRouter.enable = true;
}
