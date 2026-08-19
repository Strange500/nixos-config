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

  # Setup persistent directory for Hermes state
  systemd.tmpfiles.rules = [
    "d /persist/hermes 0755 root root -"
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
          PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/strange/.nix-profile/bin:/run/current-system/sw/bin";
        };
        volumes = [
          "/persist/hermes:/opt/data"
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
          "/persist/hermes:/opt/data"
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

  # Generate dynamic environment file for GH_TOKEN before the container starts
  systemd.services.hermes = {
    serviceConfig = {
      ExecStartPre = [
        "+${pkgs.bash}/bin/bash -c 'mkdir -p /var/lib/hermes && touch /var/lib/hermes/dynamic-env'"
        "+${pkgs.bash}/bin/bash -c 'if [ -f /run/user/1000/secrets/github_token ]; then echo \"GH_TOKEN=$(cat /run/user/1000/secrets/github_token)\" > /var/lib/hermes/dynamic-env; fi'"
      ];
    };
  };

  qgroget.services.hermes = {
    subdomain = "hermes";
    url = "http://127.0.0.1:9119";
    type = "private";
    traefikDynamicConfig = {
      http.services.hermes.loadBalancer.passHostHeader = false;
    };
  };
}
