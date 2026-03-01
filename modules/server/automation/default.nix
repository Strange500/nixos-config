{
  config,
  pkgs,
  lib,
  ...
}: let
  pythonRunnerPackages = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gawk
    pkgs.jq
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.setuptools
    pkgs.python3Packages.wheel
  ];
in {
  sops.secrets = {
    "server/n8n/secretKey" = {
    };
  };
  services.n8n = {
    enable = true;
    environment = {
      WEBHOOK_URL = "https://n8n.${config.qgroget.server.domain}";
      N8N_HOST = "n8n.${config.qgroget.server.domain}";
      N8N_PROTOCOL = "https";
      NODES_EXCLUDE = "[]";
      N8N_RUNNERS_AUTH_TOKEN_FILE = config.sops.secrets."server/n8n/secretKey".path;
    };

    taskRunners = {
      enable = true;
      environment = {
        N8N_RUNNERS_AUTH_TOKEN_FILE = config.sops.secrets."server/n8n/secretKey".path;
      };
      runners.python.environment.PATH = lib.makeBinPath pythonRunnerPackages;
    };
  };

  qgroget.services.n8n = {
    name = "n8n";
    url = "http://127.0.0.1:5678";
    type = "public";
    persistedData = [
      "/var/lib/private/n8n"
    ];
  };

  security.sudo.extraRules = [
    {
      users = ["workflow"];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl start downloaders-pod.service";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop downloaders-pod.service";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl restart downloaders-pod.service";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl status *";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # create a user for n8n, to allow ssh connections via a ssh node in a workflow, setup ssh keys and permissions for the user, and allow it to run systemctl commands to start/stop/restart services
  users.users.workflow = {
    isNormalUser = true;
    home = "/home/workflow";
    shell = pkgs.zsh;
    description = "workflow user";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcUXXV5N6nYM+GxOrTGgtkNNHBxZegdt+Ry81nI53bb strange@Server"
    ];
  };
}
