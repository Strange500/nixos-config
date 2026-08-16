{config, ...}: {
  sops.secrets."server/nanobot/env" = {};

  virtualisation.quadlet = {
    containers.nanobot = {
      autoStart = true;
      containerConfig = {
        name = "nanobot";
        image = "ghcr.io/hku-ds/nanobot:latest"; # Replace with the correct nanobot image if different
        environmentFiles = [
          "${config.sops.secrets."server/nanobot/env".path}"
        ];

        # Security hardening (no file interaction, strict permissions)
        readOnly = true;
        # Drop all capabilities that are not needed
        dropCapabilities = ["ALL"];
        # Run as a random unprivileged user
        user = "10000:10000";
        # Prevent gaining new privileges
        noNewPrivileges = true;
      };
      serviceConfig = {
        Restart = "unless-stopped";
      };
    };
  };
}
