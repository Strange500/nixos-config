{
  config,
  pkgs,
  ...
}: let
  cfg = {
    containerDir = "${config.qgroget.server.containerDir}/nanobot";
  };

  nanobotConfig = pkgs.writeText "config.json" ''
    {
      "providers": {
        "gemini": {
          "apiKey": "''${GEMINI_API_KEY}"
        }
      },
      "modelPresets": {
        "primary": {
          "provider": "gemini",
          "model": "gemini-1.5-pro-latest"
        }
      },
      "agents": {
        "defaults": {
          "modelPreset": "primary"
        }
      }
    }
  '';
in {
  sops.secrets."server/nanobot/env" = {};

  # Create the isolated workspace directory
  environment.etc."tmpfiles.d/nanobot.conf".text = ''
    d ${cfg.containerDir}/workspace 0700 10000 10000 -
  '';

  virtualisation.quadlet = {
    containers.nanobot = {
      autoStart = true;
      containerConfig = {
        name = "nanobot";
        # Since there's no official image on ghcr.io, we use python slim and install at runtime.
        # It's quick and ensures you have the latest nanobot-ai.
        image = "python:3.11-slim";

        volumes = [
          # Inject the ready-to-use config directly from the Nix store
          "${nanobotConfig}:/root/.nanobot/config.json:ro"
          # Mount the persistent workspace securely
          "${cfg.containerDir}/workspace:/root/.nanobot/workspace:Z"
        ];

        environmentFiles = [
          "${config.sops.secrets."server/nanobot/env".path}"
        ];

        # Install the nanobot-ai package and launch the gateway
        exec = "bash -c 'pip install --no-cache-dir nanobot-ai && nanobot gateway'";

        # Strict security rules. We do not use readOnly=true because pip needs to install modules
        # but we drop capabilities and prevent it from gaining new privileges.
        dropCapabilities = ["ALL"];
        noNewPrivileges = true;
        # Map exposed gateway port if you want to access the WebUI locally
        publishPorts = ["8765:8765"];
      };
      serviceConfig = {
        Restart = "unless-stopped";
      };
    };
  };
}
