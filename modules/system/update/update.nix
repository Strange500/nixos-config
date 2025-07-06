{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = {
    operation = "switch";
    configDir = /home/strange/nixos;
    user = "strange";
    pushUpdates = false;
    extraFlags = "";
    onCalendar = "daily";
    persistent = true;
  };
in {
  environment.systemPackages = [
    (import ./auto-upgrade-script.nix {
      inherit pkgs;
    })
  ];

  systemd = {
    services."nixos-upgrade" = {
      serviceConfig = {
        Type = "oneshot";
      };
      path = with pkgs; [
        git
        sudo
      ];
      unitConfig.RequiresMountsFor = "/home/strange/nixos";
      script = "${import ./auto-upgrade-script.nix {inherit pkgs;}}/bin/auto-upgrade-script";
      description = "NixOS Upgrade Service";
    };
    timers."nixos-upgrade" = {
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = cfg.persistent;
        Unit = "nixos-upgrade.service";
        RandomizedDelaySec = "30m";
      };
    };
  };
}
