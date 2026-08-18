{
  config,
  pkgs,
  ...
}: {
  # Define the SOPS secrets for Hermes
  sops.secrets."server/hermes/env" = {};
  sops.secrets."server/hermes/gog-password" = {
    owner = config.qgroget.user.username;
  };

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
    "d /opt/data/hermes 0755 root root -"
  ];

  # Deploy Hermes Agent via Quadlet
  virtualisation.quadlet = {
    containers.hermes = {
      autoStart = true;
      containerConfig = {
        name = "hermes";
        image = "nousresearch/hermes-agent:latest";
        environmentFiles = [
          "${config.sops.secrets."server/hermes/env".path}"
          "/var/lib/hermes/dynamic-env"
        ];
        publishPorts = ["8642:8642"];
        volumes = [
          "/opt/data/hermes:/opt/data:Z"
        ];
      };
      serviceConfig = {
        Restart = "unless-stopped";
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
    url = "http://127.0.0.1:8642";
    type = "private";
  };
}
