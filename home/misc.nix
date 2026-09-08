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

  # Redeploy wrapper: builds the `misc` home-configuration's activation package
  # from the pinned flake and runs it. This is the rootless, CLI-free way to do
  # what `home-manager switch` does: `nix build
  # ...#homeConfigurations.misc.activationPackage` (a "home-manager-generation"
  # whose `activate` script performs the switch + backups + systemd-user reload).
  # No dependence on a `home-manager` CLI being present in the `misc` profile.
  # Hermes calls this via `sudo -u misc /home/misc/.local/bin/deploy-portfolio`.
  home.file.".local/bin/deploy-portfolio" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      FLAKE="github:strange500/nixos-config#homeConfigurations.misc.activationPackage"
      out="$(nix --extra-experimental-features 'nix-command flakes' build "$FLAKE" --no-link --print-out-paths)"
      exec "$out/activate"
    '';
  };

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