{
  config,
  pkgs,
  inputs,
  ...
}: let
  hermes-pkg = inputs.hermes-agent.packages.${pkgs.system}.default;
in {
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

  # Deploy Hermes Agent natively via systemd using the Nix flake package
  systemd.services.hermes = {
    description = "Hermes Agent Native Service";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    path = [hermes-pkg pkgs.bash];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      WorkingDirectory = "/persist/hermes";
      EnvironmentFile = [
        config.sops.secrets."server/hermes/env".path
        "/var/lib/hermes/dynamic-env"
      ];
      ExecStartPre = [
        "+${pkgs.bash}/bin/bash -c 'mkdir -p /var/lib/hermes && touch /var/lib/hermes/dynamic-env'"
        "+${pkgs.bash}/bin/bash -c 'if [ -f /run/user/1000/secrets/github_token ]; then echo \"GH_TOKEN=$(cat /run/user/1000/secrets/github_token)\" > /var/lib/hermes/dynamic-env; fi'"
      ];
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec hermes gateway start'";
    };
  };

  systemd.services.hermes-dashboard = {
    description = "Hermes Agent Dashboard Native Service";
    wantedBy = ["multi-user.target"];
    after = ["hermes.service"];
    requires = ["hermes.service"];
    path = [hermes-pkg pkgs.bash];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      WorkingDirectory = "/persist/hermes";
      EnvironmentFile = [
        config.sops.secrets."server/hermes/env".path
        "/var/lib/hermes/dynamic-env"
      ];
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec hermes dashboard --host 127.0.0.1 --port 9119 --no-open'";
    };
  };

  qgroget.services.hermes = {
    subdomain = "hermes";
    url = "http://127.0.0.1:9119";
    type = "private";
  };
}
