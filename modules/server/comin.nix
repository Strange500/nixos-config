{
  config,
  lib,
  ...
}: let
  cfg = config.qgroget.server.comin;
in {
  config = lib.mkIf cfg.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/Strange500/nixos-config.git";
          branches.main.name = "main";
        }
      ];
    };

    # Alert (Telegram via n8n) when a comin deploy/switch fails. Reuses the
    # generic backup-failure-notify@ template (defined in modules/server/backup,
    # present on Server): %n carries "comin.service". Without this, a wedged
    # autodeploy (like Oct 2026's 7-day freeze) goes completely unnoticed.
    systemd.services.comin.onFailure = [ "backup-failure-notify@%n.service" ];

    # Persist comin's deployment history + last-deployed commit across reboots
    # (impermanence: /var/lib is ephemeral on Server).
    environment.persistence."/persist".directories = [
      "/var/lib/comin"
    ];
  };
}