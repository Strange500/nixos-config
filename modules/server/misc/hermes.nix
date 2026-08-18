{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Define the SOPS secrets for Hermes
  sops.secrets."server/hermes/gemini-api-key" = {
    owner = config.qgroget.user.username;
  };
  sops.secrets."server/hermes/telegram-token" = {
    owner = config.qgroget.user.username;
  };
  sops.secrets."server/hermes/gateway-token" = {
    owner = config.qgroget.user.username;
  };
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
    ];
  };

  # Hermes Agent NixOS Module
  imports = [
    inputs.hermes.nixosModules.default
  ];

  services.hermes-agent = {
    enable = true;
    container.enable = false;
    addToSystemPackages = true;

    # We do NOT define settings here so the migration command (`hermes claw migrate`)
    # can safely write the migrated config into ~/.hermes/config.yaml without NixOS overwriting it.
  };

  # Generate environment file with secrets before the service starts
  systemd.services.hermes-agent = {
    serviceConfig = {
      ExecStartPre = [
        "+${pkgs.bash}/bin/bash -c 'mkdir -p /var/lib/hermes && echo \"GEMINI_API_KEY=$(cat ${config.sops.secrets."server/hermes/gemini-api-key".path})\" > /var/lib/hermes/env'"
        "+${pkgs.bash}/bin/bash -c 'echo \"TELEGRAM_TOKEN=$(cat ${config.sops.secrets."server/hermes/telegram-token".path})\" >> /var/lib/hermes/env'"
        "+${pkgs.bash}/bin/bash -c 'echo \"GH_TOKEN=$(cat /run/user/1000/secrets/github_token)\" >> /var/lib/hermes/env'"
      ];
      EnvironmentFile = ["-/var/lib/hermes/env"];
    };
  };

  qgroget.services.hermes = {
    subdomain = "hermes";
    url = "http://127.0.0.1:18789"; # Ensure this matches Hermes default port
    type = "private";
  };
}
