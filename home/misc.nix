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

  # Rootless portfolio: run the real Next.js standalone production server
  # (`server.js`, not a static export) directly, as a systemd user unit under
  # the `misc` user. `home-manager switch --flake .#misc` touches only
  # /home/misc, never system units or prod. No nginx/container round-trip: the
  # derivation embeds nodejs, so `${pkg}/bin/portfolio` just works.
  systemd.user.services.portfolio = {
    Unit = {
      Description = "Next.js portfolio server (rootless)";
      After = ["network.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${inputs.portfolio.packages.${pkgs.system}.default}/bin/portfolio";
      Restart = "always";
      RestartSec = "10";
      Environment = [
        "HOSTNAME=127.0.0.1"
        "PORT=3001"
      ];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Expose behind the central Traefik proxy, unchanged routing
  # (portfolio.qgroget.com -> 127.0.0.1:3001, public, no googlenoindex).
  qgroget.traefikRouter.enable = true;
  qgroget.services.portfolio = {
    subdomain = "portfolio";
    url = "http://127.0.0.1:3001";
    type = "public";
  };
}