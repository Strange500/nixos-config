{
  pkgs,
  serverConfig,
}: let
  inherit (pkgs) lib;
  cfg = serverConfig.services.hermes-webui;
  unit = serverConfig.systemd.services.hermes-webui;
  service = serverConfig.qgroget.services.hermes-webui;
  router = serverConfig.qgroget.services.proxy.traefikDynamicConfig.http.routers.hermes-webui;
  python = pkgs.python3.withPackages (ps: [ps.pyyaml ps.cryptography]);
in
  assert lib.assertMsg (serverConfig.services ? hermes-webui && cfg.enable) "Server must enable the upstream Hermes WebUI module";
  assert !(serverConfig.virtualisation.quadlet.containers ? hermes-webui);
  assert cfg.host == "127.0.0.1" && cfg.port == 8787 && !cfg.openFirewall;
  assert service.type == "private" && router.tls.options == "mtls";
  assert service.url == "http://127.0.0.1:8787";
  assert cfg.hermesHome == "/opt/data";
  assert cfg.extraEnvironment.HERMES_WEBUI_AUTO_INSTALL == "0";
  assert cfg.extraEnvironment.HERMES_WEBUI_CHAT_BACKEND == "gateway";
  assert cfg.extraEnvironment.HERMES_WEBUI_GATEWAY_BASE_URL == "http://127.0.0.1:8642";
  assert cfg.extraEnvironment.HERMES_WEBUI_GATEWAY_USE_RUNS_API == "true";
  # Podman forwards to the pod's interface, not its loopback listener.
  assert lib.assertMsg
  ((serverConfig.virtualisation.quadlet.containers.hermes.containerConfig.environments.API_SERVER_HOST or null) == "0.0.0.0")
  "Hermes API must bind the pod interface for the native WebUI";
  assert lib.elem "127.0.0.1:8642:8642" serverConfig.virtualisation.quadlet.pods.honcho.podConfig.publishPorts;
  assert serverConfig.virtualisation.quadlet.containers.hermes.containerConfig.environments.API_SERVER_PORT == "8642";
  assert !(lib.elem 8642 serverConfig.networking.firewall.allowedTCPPorts);
  assert lib.elem "/persist/hermes:/opt/data" unit.serviceConfig.BindPaths;
  assert serverConfig.users.users.hermes-webui.uid == 10000;
  assert serverConfig.users.groups.hermes-webui.gid == 10000;
  assert lib.elem "hermes.service" unit.requires && lib.elem "hermes.service" unit.after;
  assert lib.elem cfg.stateDir serverConfig.qgroget.backups.hermes.paths;
  assert lib.elem "hermes-webui.service" serverConfig.qgroget.backups.hermes.systemdUnits;
    pkgs.runCommand "hermes-webui-test" {
      nativeBuildInputs = [python];
    } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      python ${./smoke.py} ${cfg.package}/hermes-webui ${lib.escapeShellArg serverConfig.virtualisation.quadlet.containers.hermes.containerConfig.environments.API_SERVER_HOST}
      touch "$out"
    ''
