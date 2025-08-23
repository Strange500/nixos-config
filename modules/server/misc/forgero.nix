{
  lib,
  config,
  ...
}: let
  cfg = config.services.forgejo;
  port = 8082;
in {
  # Configure permissions for forgejo service
  qgroget.server.permissions.services.forgejo = {
    user = "forgejo";
    group = "forgejo";
    homeDir = "/var/lib/forgejo";
    directories = [
      {
        path = "${cfg.stateDir}";
        mode = "2700";
        type = "d";
      }
      {
        path = "${cfg.stateDir}";
        mode = "-";
        type = "Z";
      }
    ];
    secrets = {
      "server/forgejo/strange/password" = {};
      "server/forgejo/strange/mail" = {};
      "server/forgejo/strange/dbPassword" = {};
    };
  };

  qgroget.services.git = {
    name = "git";
    url = "http://127.0.0.1:${toString port}";
    type = "private";
  };

  qgroget.backups.git = {
    paths = [
      "${cfg.stateDir}"
      "/var/lib/mysql"
    ];
    systemdUnits = [
      "forgejo.service"
      "mysql.service"
    ];
  };

  services.forgejo = {
    enable = true;
    database = {
      type = "mysql";
      user = "forgejo";
      passwordFile = config.sops.secrets."server/forgejo/strange/dbPassword".path;
      name = "forgejo";
      createDatabase = true;
    };
    lfs.enable = true;

    settings = {
      server = {
        DOMAIN = "git.qgroget.com";
        ROOT_URL = "https://git.qgroget.com/";

        START_SSH_SERVER = false;

        SSH_DOMAIN = "git.qgroget.com";
        SSH_PORT = 22;

        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 8082;
        PROTOCOL = "http";
      };
      service.DISABLE_REGISTRATION = true;
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };
      security = {
        REVERSE_PROXY_TRUSTED_PROXIES = "127.0.0.1";
      };
    };
  };

  services.openssh = {
    enable = true;
    ports = [2222];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      UseDns = true;
    };
    extraConfig = ''
      # Deny all other users on port 2222
      Match LocalPort 2222
      AllowUsers forgejo
    '';
  };

  environment.persistence."/persist".directories = [
    "${config.services.forgejo.stateDir}"
  ];

  # Additional ACL setup for forgejo directories
  environment.etc."tmpfiles.d/forgejo-acl.conf".text = ''
    # Set default ACLs so new files/dirs inherit group permissions
    a+ ${config.services.forgejo.stateDir} - - - - \
      d:g:forgejo:r-x,d:g:forgejo:r--,g:forgejo:r-x,g:forgejo:r--
  '';

  systemd.services.forgejo.preStart = let
    adminCmd = "${lib.getExe cfg.package} admin user";
    PasswordPath = config.sops.secrets."server/forgejo/strange/password".path;
    mailPath = config.sops.secrets."server/forgejo/strange/mail".path;
    user = "strange"; # Note, Forgejo doesn't allow creation of an account named "admin"
  in ''
    ${adminCmd} create --admin --email "$(tr -d '\n' < ${mailPath})" --username ${user} --password "$(tr -d '\n' < ${PasswordPath})" || true
    ## uncomment this line to change an admin user which was already created
    # ${adminCmd} change-password --username ${user} --password "$(tr -d '\n' < ${PasswordPath})" || true
  '';

  services.traefik.staticConfigOptions.entryPoints.ssh = {
    address = ":222";
  };

  networking.firewall.allowedTCPPorts = lib.mkIf (config.services.forgejo.enable) [
    222
  ];

  qgroget.services.git.traefikDynamicConfig.tcp.routers.forgejo-ssh = {
    rule = "HostSNI(`*`)";
    entryPoints = ["ssh"];
    service = "forgejo-ssh";
  };
  qgroget.services.git.traefikDynamicConfig.tcp.services.forgejo-ssh = {
    loadBalancer = {
      servers = [
        {address = "127.0.0.1:2222";}
      ];
    };
  };
}
