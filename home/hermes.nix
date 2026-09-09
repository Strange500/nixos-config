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

  # Redeploy wrapper: builds the `hermes` home-configuration's activation
  # package from the pinned flake and runs it (the rootless, CLI-free way to
  # do `home-manager switch`). hermes can run this directly — no sudo, no
  # dependence on a `home-manager` CLI being present. Run: `deploy-hermes`.
  home.file.".local/bin/deploy-hermes" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      FLAKE="github:strange500/nixos-config#homeConfigurations.hermes.activationPackage"
      out="$(nix --extra-experimental-features 'nix-command flakes' build "$FLAKE" --no-link --print-out-paths)"
      exec "$out/activate"
    '';
  };

  # PR-preview instance of the portfolio. Runs the `portfolio-test` flake input
  # (pinned to the feature branch under review) as a rootless systemd user
  # service on a dedicated port, entirely under the `hermes` user.
  systemd.user.services.portfolio-test = {
    Unit = {
      Description = "Next.js portfolio test instance (PR preview)";
      After = ["network.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${inputs.portfolio-test.packages.${pkgs.system}.default}/bin/portfolio";
      Restart = "always";
      RestartSec = "10";
      Environment = [
        "HOSTNAME=127.0.0.1"
        "PORT=3002"
      ];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Declare the rootless `echo-server` / `test-portfolio` the same way the
  # server declares its own services: `qgroget.services.<name>` + subdomain/url.
  # The traefik-router module generates the full dynamic config (router +
  # service + cert resolver) and writes it under /var/lib/traefik/dynamic/,
  # hot-reloaded by Traefik. `private` = mTLS (client cert required).
  qgroget.traefikRouter.enable = true;

  qgroget.services.test-portfolio = {
    subdomain = "test-portfolio";
    url = "http://127.0.0.1:3002";
    type = "private";
  };
}
