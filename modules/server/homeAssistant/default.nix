{
  config,
  lib,
  pkgs,
  ...
}: let
  images = import ../images.nix { inherit pkgs lib; };
  domain = config.qgroget.server.domain;
  configDir = "${config.qgroget.server.containerDir}/home-assistant";

  # OpenID Connect auth provider for HA, pinned declaratively (HACS not
  # required — the component is unpacked into the store and mounted read-only).
  # Updates land via nixos-rebuild alongside the image bump, matching the rest
  # of the fleet.
  hassOidcAuth = pkgs.runCommand "hass-oidc-auth-1.2.1" { buildInputs = [ pkgs.unzip ]; } ''
    mkdir -p $out
    unzip -q ${pkgs.fetchurl {
      url = "https://github.com/christiaangoossens/hass-oidc-auth/releases/download/v1.2.1/hass-oidc-auth.zip";
      hash = "sha256-5braqsqmPP1v5zOSSgXnbXUFiDYZA5hZj7JN5XzUfM0=";
    }} -d $out
  '';

  # Core HA configuration. `auth_oidc` makes the login screen offer SSO through
  # Authelia (public client + PKCE — no client secret needed). ZHA is added
  # from the UI after first login (detects the Sonoff Zigbee dongle).
  configuration = pkgs.writeText "home-assistant-configuration.yaml" ''
    # Loads default set of components
    default_config: {}

    homeassistant:
      name: Home
      time_zone: Europe/Paris

    http:
      use_x_forwarded_for: true
      trusted_proxies:
        - 127.0.0.1

    # Login through Authelia (OpenID Connect, public client + PKCE).
    # Roles map lldap groups -> HA roles, configured from the UI / this block.
    auth_oidc:
      client_id: home-assistant
      discovery_url: https://auth.${domain}/.well-known/openid-configuration
      display_name: QGroget
  '';
in {
  qgroget.services.home-assistant = {
    subdomain = "home-assistant";
    url = "http://127.0.0.1:8123";
    type = "public";
    journalctl = true;
    unitName = "home-assistant.service";
  };

  qgroget.backups.home-assistant = {
    paths = [ configDir ];
    systemdUnits = [ "home-assistant.service" ];
  };

  environment.etc."tmpfiles.d/home-assistant.conf".text = ''
    d ${configDir} 0755 root root -
    C+ ${configDir}/configuration.yaml 0644 root root ${configuration}
  '';

  virtualisation.quadlet.containers.home-assistant = {
    autoStart = true;
    containerConfig = {
      image = "docker-archive:${images.home-assistant}";

      # Host networking: mDNS/zeroconf device discovery, HomeKit, and the
      # built-in HTTP/websocket API on 8123 all bind straight on the host.
      networks = [ "host" ];

      # Sonoff Zigbee 3.0 USB Dongle Plus V2 — stable /dev/serial/by-id path
      # (never /dev/ttyUSB*, which can move across reboots).
      devices = [
        "/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_aab2cc3e5812ef11963778b8bf9df066-if00-port0"
      ];

      environments = {
        TZ = "Europe/Paris";
      };

      volumes = [
        "${configDir}:/config:Z"
        "${hassOidcAuth}:/config/custom_components/auth_oidc:ro"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
    unitConfig = {
      Requires = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };
  };

  services.authelia.instances.qgroget.settings.identity_providers.oidc.clients = [
    {
      client_id = "home-assistant";
      client_name = "Home Assistant";
      public = true;
      authorization_policy = "two_factor";
      require_pkce = true;
      pkce_challenge_method = "S256";
      redirect_uris = [
        "https://home-assistant.${domain}/auth/oidc/callback"
      ];
      scopes = [
        "openid"
        "profile"
        "email"
        "groups"
      ];
      response_types = [
        "code"
      ];
      grant_types = [
        "authorization_code"
      ];
    }
  ];
}