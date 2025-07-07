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
    pushUpdates = false;
    extraFlags = "";
    onCalendar = "daily";
    persistent = true;
  };
in {
  systemd = {
    services."nixos-upgrade" = {
      serviceConfig = {
        Type = "oneshot";
      };
      path = [
        pkgs.git
        pkgs.sudo
        pkgs.nix
        pkgs.nixos-rebuild
      ];
      unitConfig.RequiresMountsFor = "/home/${config.qgroget.user.username}/nixos";
      script = "${import ./auto-upgrade-script.nix {inherit pkgs config;}}/bin/auto-upgrade-script";
      description = "NixOS Upgrade Service";
    };
    timers."nixos-upgrade" = {
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["timers.target"];
      timerConfig = {
        OnUnitActiveSec = "6h";
        Persistent = cfg.persistent;
        Unit = "nixos-upgrade.service";
      };
    };
  };
}
