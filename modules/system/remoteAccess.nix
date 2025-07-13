{
  config,
  lib,
  pkgs,
  ...
}: let
  # Tailscale reconnection script
  tailscaleReconnectScript = pkgs.writeShellScript "tailscale-reconnect" ''
    #!/bin/bash

    # Logging function
    log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') [tailscale-dispatcher] $1" | ${pkgs.systemd}/bin/systemd-cat -t tailscale-dispatcher
    }

    # Wait a bit for network to stabilize
    sleep 2

    log "Network change detected, checking Tailscale status..."

    # Check if tailscaled is running
    if ! ${pkgs.systemd}/bin/systemctl is-active --quiet tailscale.service; then
        log "Tailscale service not running, starting..."
        ${pkgs.systemd}/bin/systemctl start tailscale.service
        sleep 3
    fi

    # Check current status
    status="$(${pkgs.tailscale}/bin/tailscale status -json 2>/dev/null | ${pkgs.jq}/bin/jq -r .BackendState 2>/dev/null || echo "Unknown")"
    log "Current Tailscale status: $status"

    # If already running, test connectivity
    if [ "$status" = "Running" ]; then
        log "Testing Tailscale connectivity..."
        if timeout 10 ${pkgs.tailscale}/bin/tailscale status --peers=false >/dev/null 2>&1; then
            log "Tailscale connection verified, no action needed."
            exit 0
        else
            log "Tailscale connectivity test failed, will reconnect..."
        fi
    fi

    # Reconnect to Tailscale
    log "Reconnecting to Tailscale..."

    # Load OAuth credentials
    if [ -f "${config.sops.secrets."tailscale/oauth/client".path}" ] && [ -f "${config.sops.secrets."tailscale/oauth/key".path}" ]; then
        export TS_API_CLIENT_ID=$(cat ${config.sops.secrets."tailscale/oauth/client".path})
        export TS_API_CLIENT_SECRET=$(cat ${config.sops.secrets."tailscale/oauth/key".path})

        # Generate new auth key and connect
        if auth_key=$(${pkgs.tailscale}/bin/get-authkey -ephemeral -tags tag:oauth 2>/dev/null); then
            if ${pkgs.tailscale}/bin/tailscale up --auth-key "$auth_key" --accept-routes --accept-dns; then
                log "Successfully reconnected to Tailscale"
            else
                log "Failed to reconnect to Tailscale"
            fi
        else
            log "Failed to generate auth key"
        fi
    else
        log "OAuth credentials not found, skipping reconnection"
    fi
  '';

  # NetworkManager dispatcher script
  networkManagerDispatcher = pkgs.writeShellScript "99-tailscale-reconnect" ''
    #!/bin/bash

    # NetworkManager dispatcher script for Tailscale
    # Arguments: interface action
    INTERFACE="$1"
    ACTION="$2"

    # Only act on specific actions and ignore loopback/tailscale interfaces
    case "$ACTION" in
        "up"|"connectivity-change")
            # Ignore tailscale and loopback interfaces
            if [[ "$INTERFACE" =~ ^(tailscale|lo) ]]; then
                exit 0
            fi

            # Run reconnection script in background to avoid blocking NetworkManager
            nohup ${tailscaleReconnectScript} >/dev/null 2>&1 &
            ;;
        *)
            # No action needed for other events
            exit 0
            ;;
    esac
  '';
in {
  config = lib.mkIf (config.qgroget.nixos.remote-access.enable) {

    environment.systemPackages = [ pkgs.waypipe ];
    users.users.${config.qgroget.user.username}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0BEci8hnaklKkXlnbagEMdf+/Ad7+USRH+ykQkYFdy ${config.qgroget.user.username}@Clovis"
    ];
    sops = lib.mkIf (config.qgroget.nixos.remote-access.tailscale.enable) {
      age.keyFile = "${config.qgroget.secretAgeKeyPath}";
      defaultSopsFile = ../../secrets/secrets.yaml;
      secrets."tailscale/oauth/client" = {
      };
      secrets."tailscale/oauth/key" = {
      };
    };
    services = {
      openssh = {
        enable = true;
        ports = [22];
        settings = {
          PasswordAuthentication = false;
          AllowUsers = ["${config.qgroget.user.username}"];
          UseDns = true;
          PermitRootLogin = "no";
        };
      };
      fail2ban = {
        enable = true;
        maxretry = 3;
        bantime = "24h";
        bantime-increment = {
          enable = true;
          formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
          overalljails = true;
        };
      };
      tailscale = lib.mkIf config.qgroget.nixos.remote-access.tailscale.enable {
        enable = true;
        useRoutingFeatures = "client";
      };

      sunshine = lib.mkIf config.qgroget.nixos.remote-access.sunshine.enable {
        enable = true;
        autoStart = true;
        capSysAdmin = false;
        openFirewall = true;
      };
    };

    networking.networkmanager.dispatcherScripts = lib.mkIf config.qgroget.nixos.remote-access.tailscale.enable [
      {
        source = networkManagerDispatcher;
        type = "basic";
      }
    ];

    systemd.services.tailscale-autoconnect = lib.mkIf config.qgroget.nixos.remote-access.tailscale.enable {
      description = "Automatic connection to Tailscale";
      after = ["network-pre.target" "tailscale.service"];
      wants = ["network-pre.target" "tailscale.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Initial connection on boot
        sleep 5
        ${tailscaleReconnectScript}
      '';
    };
  };
}
