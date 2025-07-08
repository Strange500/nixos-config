{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.qgroget.nixos.remote-access) {
    users.users.${config.qgroget.user.username}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0BEci8hnaklKkXlnbagEMdf+/Ad7+USRH+ykQkYFdy ${config.qgroget.user.username}@Clovis"
    ];
    sops = {
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
      tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
    };

    systemd = {
      services.tailscale-autoconnect = {
        description = "Automatic connection to Tailscale";

        # make sure tailscale is running before trying to connect to tailscale
        after = ["network-pre.target" "tailscale.service"];
        wants = ["network-pre.target" "tailscale.service"];
        wantedBy = ["multi-user.target"];

        # set this service as a oneshot job
        serviceConfig.Type = "oneshot";

        # have the job run this shell script
        script = ''

          # wait for tailscaled to settle
          echo "Waiting for tailscale.service start completion ..."
          sleep 5
          # (as of tailscale 1.4 this should no longer be necessary, but I find it still is)

          # check if already authenticated
          echo "Checking if already authenticated to Tailscale ..."
          status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
          if [ $status = "Running" ]; then  # do nothing
          	echo "Already authenticated to Tailscale, exiting."
            exit 0
          fi

          # otherwise authenticate with tailscale
          echo "Authenticating with Tailscale ..."
          # old: ${pkgs.tailscale}/bin/tailscale up --authkey $(cat /etc/tailscale/tskey-reusable)
          export TS_API_CLIENT_ID=$(cat ${config.sops.secrets."tailscale/oauth/client".path})
          export TS_API_CLIENT_SECRET=$(cat ${config.sops.secrets."tailscale/oauth/key".path})
          ${pkgs.tailscale}/bin/tailscale up --auth-key $(${pkgs.tailscale}/bin/get-authkey -ephemeral -tags tag:oauth)
        '';
      };
    };
  };
}
