{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = {
    operation = "switch";
    configDir = /home/${config.qgroget.user.username}/nixos;
    user = "${config.qgroget.user.username}";
    pushUpdates = true;
    extraFlags = "";
    onCalendar = "daily";
    persistent = true;
  };
in {
  config = lib.mkIf config.qgroget.nixos.auto-update {
    systemd = {
    services."nixos-upgrade" = {
      enable = config.qgroget.nixos.auto-update;
      serviceConfig = {
        Type = "oneshot";
      };
      path = [
        pkgs.git
        pkgs.sudo
        pkgs.nix
        pkgs.nixos-rebuild
        pkgs.openssh
        pkgs.gawk
      ];
      unitConfig.RequiresMountsFor = "/home/${config.qgroget.user.username}/nixos";
      script = "${import ./auto-upgrade-script.nix {inherit pkgs config;}}/bin/auto-upgrade-script";
      description = "NixOS Upgrade Service";
    };
    timers."nixos-upgrade" = {
      enable = true;
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "6h";
        Persistent = cfg.persistent;
        Unit = "nixos-upgrade.service";
      };
    };
  };
  };
}
