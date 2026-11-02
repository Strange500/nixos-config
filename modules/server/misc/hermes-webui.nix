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
      PYTHONDONTWRITEBYTECODE = "1";
    };
  };

  # The shared Agent home is owned by this fixed container UID/GID. Reserve
  # those IDs for the native service rather than chmod/chown the live state.
  users.users.hermes-webui.uid = 10000;
  users.groups.hermes-webui.gid = 10000;

  systemd.services.hermes-webui = {
    requires = ["hermes.service"];
    after = ["hermes.service"];
    partOf = ["hermes.service"];
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

  # The third-party WebUI has no OIDC integration here. Keep the built-in
  # dashboard at hermes.<domain> and require client-certificate auth here.
  qgroget.services.hermes-webui = {
    subdomain = "hermes-webui";
    url = "http://127.0.0.1:8787";
    type = "private";
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

  qgroget.backups.hermes = {
    paths = ["/persist/hermes" cfg.stateDir];
    # Quiesce all writers before copying shared SQLite/session state.
    systemdUnits = ["hermes-webui.service" "hermes-dashboard.service" "hermes.service"];
  };
}
