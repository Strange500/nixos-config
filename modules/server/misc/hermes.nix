{
  config,
  pkgs,
  ...
}: {
  # Define the SOPS secrets for Hermes
  sops.secrets."server/hermes/gemini-api-key" = {};
  sops.secrets."server/hermes/telegram-token" = {};
  sops.secrets."server/hermes/gateway-token" = {};
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

  # Deploy Hermes Agent via Podman
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers."hermes" = {
    image = "nousresearch/hermes-agent:latest";
    autoStart = true;
    volumes = [
      "/opt/data/hermes:/opt/data"
    ];
    environmentFiles = [
      "/var/lib/hermes/env"
    ];
    ports = [
      "8642:8642"
    ];
  };

  # Generate environment file with secrets before the container starts
  systemd.services."podman-hermes" = {
    serviceConfig = {
      ExecStartPre = [
        "+${pkgs.bash}/bin/bash -c 'mkdir -p /var/lib/hermes && echo \"GEMINI_API_KEY=$(cat ${config.sops.secrets."server/hermes/gemini-api-key".path})\" > /var/lib/hermes/env'"
        "+${pkgs.bash}/bin/bash -c 'echo \"TELEGRAM_TOKEN=$(cat ${config.sops.secrets."server/hermes/telegram-token".path})\" >> /var/lib/hermes/env'"
        "+${pkgs.bash}/bin/bash -c 'if [ -f /run/user/1000/secrets/github_token ]; then echo \"GH_TOKEN=$(cat /run/user/1000/secrets/github_token)\" >> /var/lib/hermes/env; fi'"
      ];
    };
  };

  qgroget.services.hermes = {
    subdomain = "hermes";
    url = "http://127.0.0.1:8642";
    type = "private";
  };
}
