{
  config,
  pkgs,
  ...
}: {
  services.n8n = {
    enable = true;
    environment = {
      WEBHOOK_URL = "https://n8n.${config.qgroget.server.domain}";
      N8N_HOST = "n8n.${config.qgroget.server.domain}";
      N8N_PROTOCOL = "https";
      NODES_EXCLUDE = "[]";
    };

    taskRunners.enable = true;
  };

  qgroget.services.n8n = {
    name = "n8n";
    url = "http://127.0.0.1:5678";
    type = "public";
  };

  # add python to systemd.services.n8n.serviceConfig.Environment
  systemd.services.n8n.serviceConfig.Environment = "PATH=${pkgs.python3}/bin:\$PATH";

  security.sudo.extraRules = [
    {
      users = ["n8n"];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
