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
}
