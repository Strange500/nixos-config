{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    "crowdsec/enrollKey" = {
      group = "crowdsec";
      owner = "crowdsec";
    };
  };

  users.users.crowdsec.extraGroups = ["systemd-journal"];


  services.crowdsec = let
    # Generate acquisition file with multiple sources
    acquisitions_file = pkgs.writeText "acquisitions.yaml" ''
      ---
      filenames:
      - "/var/lib/jellyfin/log/log_*"
      labels:
        type: jellyfin
      ---
      filenames:
      - "/containers/jellyseer/config/logs/jellyseerr.log"
      labels:
        type: jellyseerr
      poll_without_inotify: true
    '';
  in {
    enable = true;
    enrollKeyFile = "${config.sops.secrets."crowdsec/enrollKey".path}";
    allowLocalJournalAccess = true;

    settings = {
      crowdsec_service.acquisition_path = acquisitions_file;
      api.server = {
        listen_uri = "127.0.0.1:8887";
      };
    };
  };

  systemd.services.crowdsec = {
    serviceConfig = {
      ExecStartPre = let
        script = pkgs.writeScriptBin "register-collections" ''
          #!${pkgs.runtimeShell}
          set -eu

          # Wait longer and check if API is responding
          for i in {1..30}; do
            if cscli version >/dev/null 2>&1; then
              break
            fi
            echo "Waiting for CrowdSec API... ($i/30)"
            sleep 2
          done

          # Install with better error handling
          echo "Installing collections..."
          cscli collections install crowdsecurity/linux
          cscli collections install LePresidente/jellyfin
          cscli collections install LePresidente/jellyseerr

          # Install parsers
          cscli parsers install crowdsecurity/syslog-logs
          cscli parsers install crowdsecurity/dateparse-enrich

          echo "Collections installed successfully"
        '';
      in ["${script}/bin/register-collections"];
    };
    after = ["network.target"];
    wants = ["network.target"];
  };
}
