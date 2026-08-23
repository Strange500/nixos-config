{
  config,
  pkgs,
  ...
}: {
  # Define the SOPS secrets for Hermes
  sops.secrets."server/hermes/env" = {};

  # Keep user packages (chromium, gh, etc.)
  home-manager.users.${config.qgroget.user.username} = {
    home.packages = [
      pkgs.chromium
      pkgs.nss
      pkgs.gh
      pkgs.jq
      pkgs.gogcli
    ];
  };

  # The `hermes` host user's Home Manager config (git/gh CLI + rootless quadlet
  # sandbox) is managed STANDALONE, not here: see `home/hermes.nix` and the
  # `homeConfigurations.hermes` flake output. The agent activates it rootlessly
  # via `home-manager switch --flake .#hermes`, touching only /home/hermes.

  # Setup persistent directory for Hermes state
  systemd.tmpfiles.rules = [
    "d /persist/hermes 0755 10000 10000 -"
  ];

  # User hermes on host for remote management & agent integration
  users.users.hermes = {
    isNormalUser = true;
    home = "/home/hermes";
    shell = pkgs.zsh;
    description = "Hermes Agent";
    # Keep user services (rootless quadlets) alive across reboots without login.
    linger = true;
    # Dynamic subuid/subgid ranges for rootless multi-user podman.
    autoSubUidGidRange = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNOmRynM+21pbOfNV+di0ZuYzzz0SptYG212pqsm5ZW hermes-agent@qgroget.com"
    ];
    extraGroups = [
      "podman"
      "nix-users"
      "systemd-journal"
      "media"
    ];
  };

  # Scoped sudo rules for hermes (no full root access)
  security.sudo.extraRules = [
    {
      users = ["hermes"];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl status *";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl is-active *";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl restart hermes.service";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl restart hermes-dashboard.service";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl restart honcho-api.service";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/journalctl *";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # Deploy Hermes Agent via Quadlet
  virtualisation.quadlet = {
    containers.hermes = {
      autoStart = true;
      containerConfig = {
        name = "hermes";
        image = "docker.io/nousresearch/hermes-agent:latest";
        pod = config.virtualisation.quadlet.pods.honcho.ref;
        environmentFiles = [
          "${config.sops.secrets."server/hermes/env".path}"
          "/var/lib/hermes/dynamic-env"
        ];
        environments = {
          PATH = "/opt/hermes/.venv/bin:/command:/opt/hermes/bin:/opt/data/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/strange/.nix-profile/bin:/run/current-system/sw/bin";
          XDG_CONFIG_HOME = "/home/strange/.config";
        };
        volumes = [
          "/persist/hermes:/opt/data:Z"
          "/nix/store:/nix/store:ro"
          "/home/strange:/home/strange"
          "/run/current-system/sw/bin:/run/current-system/sw/bin:ro"
        ];
        podmanArgs = [
          "--tty"
          "--interactive"
        ];
      };
      serviceConfig = {
        Restart = "always";
        After = ["honcho-api.service"];
        Requires = ["honcho-api.service"];
        ExecStartPre = [
          "+${pkgs.bash}/bin/bash -c 'mkdir -p /var/lib/hermes && touch /var/lib/hermes/dynamic-env'"
          "+${pkgs.bash}/bin/bash -c 'if [ -f /run/user/1000/secrets/github_token ]; then echo \"GH_TOKEN=$(cat /run/user/1000/secrets/github_token)\" > /var/lib/hermes/dynamic-env; echo \"GITHUB_TOKEN=$(cat /run/user/1000/secrets/github_token)\" >> /var/lib/hermes/dynamic-env; fi'"
        ];
      };
    };
    containers.hermes-dashboard = {
      autoStart = true;
      containerConfig = {
        name = "hermes-dashboard";
        image = "docker.io/nousresearch/hermes-agent:latest";
        networks = ["host"];
        environmentFiles = [
          "${config.sops.secrets."server/hermes/env".path}"
          "/var/lib/hermes/dynamic-env"
        ];
        volumes = [
          "/persist/hermes:/opt/data:Z"
        ];
        podmanArgs = [
          "--entrypoint=[\"hermes\", \"dashboard\", \"--host\", \"127.0.0.1\", \"--port\", \"9119\", \"--no-open\", \"--skip-build\"]"
        ];
      };
      serviceConfig = {
        Restart = "always";
        After = ["hermes.service"];
        Requires = ["hermes.service"];
      };
    };
  };

  qgroget.services.hermes = {
    subdomain = "hermes";
    url = "http://127.0.0.1:9119";
    type = "private";
    middlewares = ["hermes-origin"];
    traefikDynamicConfig = {
      http.middlewares.hermes-origin.headers.customRequestHeaders.Origin = "http://127.0.0.1:9119";
      http.services.hermes.loadBalancer.passHostHeader = false;
    };
  };
}
