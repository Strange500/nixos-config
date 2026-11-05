{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-webui;
  python = pkgs.python3.withPackages (ps: [ps.pyyaml ps.cryptography]);
in {
  imports = [inputs.hermes-webui.nixosModules.default];

  # Use upstream's native package and service module. The Agent remains in its
  # existing Quadlet container; browser turns use its authenticated Runs API.
  services.hermes-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 8787;
    openFirewall = false;
    hermesHome = "/opt/data";
    # No host-side Agent is configured; browser turns are routed to the gateway.
    agent.dir = "/var/empty";
    environmentFiles = [config.sops.secrets."server/hermes/env".path];
    extraEnvironment = {
      HERMES_WEBUI_AUTO_INSTALL = "0";
      HERMES_WEBUI_CHAT_BACKEND = "gateway";
      HERMES_WEBUI_GATEWAY_BASE_URL = "http://127.0.0.1:8642";
      HERMES_WEBUI_GATEWAY_USE_RUNS_API = "true";
      HERMES_WEBUI_SERVER_CWD = cfg.stateDir;
      # Supported by pinned upstream 40e09c0. Native Traefik uses IPv4 loopback.
      HERMES_WEBUI_TRUSTED_AUTH_HEADER = "Remote-User";
      HERMES_WEBUI_TRUSTED_PROXY_CIDRS = "127.0.0.1/32";
      PYTHONDONTWRITEBYTECODE = "1";
    };
  };

  # The shared Agent home is owned by this fixed container UID/GID. Reserve
  # those IDs for the native service rather than chmod/chown the live state.
  users.users.hermes-webui.uid = 10000;
  users.groups.hermes-webui.gid = 10000;

  systemd.services.hermes-webui = {
    requires = ["hermes.service" "firewall.service"];
    after = ["hermes.service" "firewall.service"];
    partOf = ["hermes.service" "firewall.service"];
    serviceConfig = {
      # Upstream's bootstrap currently insists on a LOCAL Agent even when
      # CHAT_BACKEND=gateway. Keep its packaged server and module, but launch
      # server.py directly with the same minimal Nix Python dependencies.
      ExecStart = lib.mkForce "${python}/bin/python3 ${cfg.package}/hermes-webui/server.py";
      WorkingDirectory = cfg.stateDir;
      # Preserve /opt/data paths in existing profiles/configs and gateway
      # requests, without exposing any other container or host directories.
      BindPaths = ["/persist/hermes:/opt/data"];
      ProtectSystem = "strict";
      ReadWritePaths = ["/opt/data" cfg.stateDir];
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      RestartSec = "5s";
      TimeoutStopSec = "120s";
    };
  };

  # Only this router replaces mTLS with Authelia two-factor authentication.
  qgroget.services.hermes-webui = {
    subdomain = "hermes-webui";
    url = "http://127.0.0.1:8787";
    type = "public";
    middlewares = ["hermes-webui-strip-identity" "SSO"];
    traefikDynamicConfig.http.middlewares.hermes-webui-strip-identity.headers.customRequestHeaders = {
      Remote-User = "";
      Remote-Groups = "";
      Remote-Email = "";
      Remote-Name = "";
    };
    persistedData = [
      {
        directory = cfg.stateDir;
        user = cfg.user;
        group = cfg.group;
        mode = "0700";
      }
    ];
    journalctl = true;
    unitName = "hermes-webui.service";
  };

  services.authelia.instances.qgroget.settings.access_control.rules = lib.mkAfter [
    {
      domain = "hermes-webui.${config.qgroget.server.domain}";
      policy = "two_factor";
      subject = ["group:admin"];
    }
  ];

  # Upstream implicitly trusts loopback independently of the explicit CIDR.
  # Only Traefik may connect locally; root and writers of proxy config are
  # necessarily trusted. No other route/firewall port is changed.
  networking.firewall.extraCommands = ''
    iptables -I OUTPUT 1 -p tcp -d 127.0.0.1 --dport 8787 -m owner ! --uid-owner traefik -j REJECT --reject-with tcp-reset
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D OUTPUT -p tcp -d 127.0.0.1 --dport 8787 -m owner ! --uid-owner traefik -j REJECT --reject-with tcp-reset 2>/dev/null || true
  '';

  assertions = [
    {
      assertion = cfg.host == "127.0.0.1" && cfg.port == 8787 && !cfg.openFirewall;
      message = "Hermes trusted-header SSO requires a loopback-only backend on port 8787.";
    }
    {
      assertion = config.networking.firewall.enable && !config.networking.nftables.enable;
      message = "Hermes local proxy UID guard requires the enabled iptables firewall.";
    }
    {
      assertion = cfg.extraEnvironment.HERMES_WEBUI_TRUSTED_AUTH_HEADER == "Remote-User" && cfg.extraEnvironment.HERMES_WEBUI_TRUSTED_PROXY_CIDRS == "127.0.0.1/32";
      message = "Hermes must trust only native Traefik loopback and Authelia Remote-User.";
    }
  ];

  qgroget.backups.hermes = {
    paths = ["/persist/hermes" cfg.stateDir];
    # Quiesce all writers before copying shared SQLite/session state.
    systemdUnits = ["hermes-webui.service" "hermes-dashboard.service" "hermes.service"];
  };
}
