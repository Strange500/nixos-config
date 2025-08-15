{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.qgroget.services;

  # Collection definitions with better organization
  collections = {
    base = [
      "crowdsecurity/linux"
    ];
    applications = [
      "LePresidente/jellyfin"
      "LePresidente/jellyseerr"
      "LePresidente/adguardhome"
      "firix/authentik"
      "gauth-fr/immich"
      "sdwilsh/navidrome"
      "Dominic-Wagner/vaultwarden"
    ];
  };

  # Flatten all collections into a single list
  allCollections = lib.flatten (lib.attrValues collections);

  # Parser definitions
  parsers = [
    "crowdsecurity/syslog-logs"
    "crowdsecurity/dateparse-enrich"
  ];

  # Generate acquisition configuration for a service
  generateAcquisition = service:
    if service ? journalctl && service.journalctl == true
    then ''
      ---
      journalctl_filter:
        - "_SYSTEMD_UNIT=${service.unitName}"
      labels:
        type: ${service.name}
    ''
    else
      lib.optionalString (service.logPath != "") ''
        ---
        filenames:
          - "${service.logPath}"
        labels:
          type: ${service.name}
        poll_without_inotify: true
      '';

  # Generate install command for collections/parsers
  generateInstallCmd = type: item: "cscli ${type} install ${item}";

  # Create the complete acquisitions configuration
  acquisitionsConfig = lib.concatStringsSep "\n" (
    map generateAcquisition (lib.attrValues cfg)
  );

  # Write acquisitions to a file
  acquisitionsFile = pkgs.writeText "acquisitions.yaml" acquisitionsConfig;

  # Create the setup script
  setupScript = pkgs.writeScriptBin "crowdsec-setup" ''
    #!${pkgs.runtimeShell}
    set -euo pipefail

    # Function to wait for CrowdSec API
    wait_for_api() {
      local max_attempts=30
      local attempt=1

      echo "Waiting for CrowdSec API to be ready..."

      while [ $attempt -le $max_attempts ]; do
        if cscli version >/dev/null 2>&1; then
          echo "CrowdSec API is ready"
          return 0
        fi

        echo "Attempt $attempt/$max_attempts: API not ready, waiting..."
        sleep 2
        ((attempt++))
      done

      echo "ERROR: CrowdSec API failed to start after $max_attempts attempts"
      return 1
    }

    # Function to install collections
    install_collections() {
      echo "Installing collections..."
      ${lib.concatStringsSep "\n    " (map (generateInstallCmd "collections") allCollections)}
      echo "Collections installed successfully"
    }

    # Function to install parsers
    install_parsers() {
      echo "Installing parsers..."
      ${lib.concatStringsSep "\n    " (map (generateInstallCmd "parsers") parsers)}
      echo "Parsers installed successfully"
    }

    # Main execution
    main() {
      wait_for_api || exit 1
      install_collections
      install_parsers
      echo "CrowdSec setup completed successfully"
    }

    main "$@"
  '';
in {
  config = {
    # SOPS secrets configuration
    sops.secrets."crowdsec/enrollKey" = {
      group = "crowdsec";
      owner = "crowdsec";
    };

    users.users.crowdsec.extraGroups = ["systemd-journal"];

    # CrowdSec service configuration
    services.crowdsec = {
      enable = true;
      enrollKeyFile = config.sops.secrets."crowdsec/enrollKey".path;
      allowLocalJournalAccess = true;

      settings = {
        crowdsec_service.acquisition_path = acquisitionsFile;
        api.server.listen_uri = "127.0.0.1:8887";
      };
    };

    # Systemd service overrides
    systemd.services.crowdsec = {
      after = ["network.target"];
      wants = ["network.target"];

      serviceConfig = {
        ExecStartPre = ["${setupScript}/bin/crowdsec-setup"];
        # Add restart policies for better resilience
        Restart = "on-failure";
        RestartSec = "10s";

        PrivateUsers = false;
        SupplementaryGroups = ["systemd-journal"];
      };
    };

    # Optional: Add a timer for periodic collection updates
    systemd.services.crowdsec-update-collections = {
      description = "Update CrowdSec collections and parsers";
      serviceConfig = {
        Type = "oneshot";
        User = "crowdsec";
        Group = "crowdsec";
        ExecStart = pkgs.writeScript "update-collections" ''
          #!${pkgs.runtimeShell}
          set -euo pipefail

          echo "Updating CrowdSec collections..."
          cscli collections upgrade --all || true
          cscli parsers upgrade --all || true
          echo "Update completed"
        '';
      };
    };

    systemd.timers.crowdsec-update-collections = {
      description = "Update CrowdSec collections weekly";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
