{
  pkgs,
  serverConfig,
}: let
  inherit (pkgs) lib;
  cfg = serverConfig.services.hermes-webui;
  unit = serverConfig.systemd.services.hermes-webui;
  service = serverConfig.qgroget.services.hermes-webui;
  router = serverConfig.qgroget.services.proxy.traefikDynamicConfig.http.routers.hermes-webui;
  sso = serverConfig.qgroget.services.auth.traefikDynamicConfig.http.middlewares.SSO;
  strip = service.traefikDynamicConfig.http.middlewares.hermes-webui-strip-identity;
  proxyConfig = pkgs.writeText "hermes-sso-test.json" (builtins.toJSON {
    inherit router sso strip;
  });
  python = pkgs.python3.withPackages (ps: [ps.pyyaml ps.cryptography]);
in
  assert lib.assertMsg (serverConfig.services ? hermes-webui && cfg.enable) "Server must enable the upstream Hermes WebUI module";
  assert !(serverConfig.virtualisation.quadlet.containers ? hermes-webui);
  assert cfg.host == "127.0.0.1" && cfg.port == 8787 && !cfg.openFirewall;
  assert lib.assertMsg (service.type == "public" && !(router.tls ? options)) "Hermes WebUI must use SSO, not mTLS";
  assert router.middlewares == ["hermes-webui-strip-identity" "SSO" "googlenoindex"];
  assert cfg.extraEnvironment.HERMES_WEBUI_TRUSTED_AUTH_HEADER == "Remote-User";
  assert cfg.extraEnvironment.HERMES_WEBUI_TRUSTED_PROXY_CIDRS == "127.0.0.1/32";
  assert sso.forwardAuth.address == "http://127.0.0.1:9091/api/authz/forward-auth";
  assert sso.forwardAuth.authResponseHeaders == ["Remote-User" "Remote-Groups" "Remote-Email" "Remote-Name"];
  assert lib.all (value: value == "") (builtins.attrValues strip.headers.customRequestHeaders);
  assert lib.any (rule: rule.domain == "hermes-webui.${serverConfig.qgroget.server.domain}" && rule.policy == "two_factor" && rule.subject == ["group:admin"]) serverConfig.services.authelia.instances.qgroget.settings.access_control.rules;
  # Every remaining private service keeps the shared mTLS policy.
  assert lib.all (name: serverConfig.qgroget.services.proxy.traefikDynamicConfig.http.routers.${name}.tls.options == "mtls")
  (builtins.attrNames (lib.filterAttrs (_: value: value.type == "private") serverConfig.qgroget.services));
  assert serverConfig.networking.firewall.enable && !serverConfig.networking.nftables.enable;
  assert lib.hasInfix "--uid-owner traefik" serverConfig.networking.firewall.extraCommands;
  assert lib.elem "firewall.service" unit.requires && lib.elem "firewall.service" unit.after;
  assert lib.elem "firewall.service" unit.partOf;
  assert serverConfig.systemd.services.traefik.serviceConfig.User == "traefik";
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
  # Dashboard/TUI clients can spawn a gateway in their own container. It shares
  # the pod port, so its inherited bind settings must match the supervised one.
  assert lib.assertMsg
  ((serverConfig.virtualisation.quadlet.containers.hermes-dashboard.containerConfig.environments.API_SERVER_HOST or null) == "0.0.0.0")
  "Dashboard-spawned gateways must also bind the pod interface";
  assert (serverConfig.virtualisation.quadlet.containers.hermes-dashboard.containerConfig.environments.API_SERVER_PORT or null) == "8642";
  assert !(lib.elem 8642 serverConfig.networking.firewall.allowedTCPPorts);
  assert lib.elem "/persist/hermes:/opt/data" unit.serviceConfig.BindPaths;
  assert serverConfig.users.users.hermes-webui.uid == 10000;
  assert serverConfig.users.groups.hermes-webui.gid == 10000;
  assert lib.elem "hermes.service" unit.requires && lib.elem "hermes.service" unit.after;
  assert lib.elem cfg.stateDir serverConfig.qgroget.backups.hermes.paths;
  assert lib.elem "hermes-webui.service" serverConfig.qgroget.backups.hermes.systemdUnits;
    pkgs.runCommand "hermes-webui-test" {
      nativeBuildInputs = [python pkgs.traefik];
    } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      python ${./sso.py} ${cfg.package}/hermes-webui ${proxyConfig}
      for bind in ${lib.escapeShellArgs (map (name: serverConfig.virtualisation.quadlet.containers.${name}.containerConfig.environments.API_SERVER_HOST) ["hermes" "hermes-dashboard"])}; do
        python ${./smoke.py} ${cfg.package}/hermes-webui "$bind"
      done
      touch "$out"
    ''
