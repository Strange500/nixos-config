{
  config,
  lib,
  ...
}: let
  cfg = config.qgroget.server.comin;
in {
  options.qgroget.server.comin = {
    enable = lib.mkEnableOption "comin GitOps deployment for the Server host";
  };

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

    # Persist comin's deployment history + last-deployed commit across reboots
    # (impermanence: /var/lib is ephemeral on Server).
    environment.persistence."/persist".directories = [
      "/var/lib/comin"
    ];
  };
}
