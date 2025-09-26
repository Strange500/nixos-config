{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  cfg = config.qgroget.services;

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

  # Generate acquisition configuration for a service
  generateAcquisition = service: let
    acq =
      if service.journalctl == true
      then {
        source = "journalctl";
        journalctl_filter = ["_SYSTEMD_UNIT=${service.unitName}"];
        labels = {type = service.name;};
      }
      else if service.logPath != ""
      then {
        source = "file";
        filenames = ["${service.logPath}"];
        poll_without_inotify = true;
        labels = {type = service.name;};
      }
      else null;
  in
    lib.optionals (acq != null) [acq]; # filter out nulls

  localAcquisitions = lib.concatLists (map generateAcquisition (lib.attrValues cfg));
in {
  sops.secrets."crowdsec/enrollKey" = {
    group = "crowdsec";
    owner = "crowdsec";
  };
  users.users.crowdsec.extraGroups = ["systemd-journal"];

  services.crowdsec = {
    enable = true;
    user = "crowdsec";

    hub.collections = allCollections;

    localConfig = {
      acquisitions = localAcquisitions;
    };

    settings.lapi.credentialsFile = "/var/lib/crowdsec/lapi.yaml";
    settings.capi.credentialsFile = "/var/lib/crowdsec/capi.yaml";
    settings.console.tokenFile = config.sops.secrets."crowdsec/enrollKey".path;

    settings.general.api.server.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnugrep
    coreutils
    systemd
  ];

  systemd.services.crowdsec.serviceConfig.Environment = ''
    PATH=${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:${pkgs.systemd}/bin:$PATH
  '';

  # disable PrivateUsers for crowdsec service to allow journal access
  systemd.services.crowdsec.serviceConfig.PrivateUsers = lib.mkForce false;

  systemd.tmpfiles.rules = [
    "d /var/lib/crowdsec 0755 crowdsec crowdsec - -"
    "f /var/lib/crowdsec/capi.yaml 0640 crowdsec crowdsec -"
  ];
}
