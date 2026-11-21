{
  lib,
  pkgs,
  ...
}: let
  # Private application repository: never fetch with a token in a derivation.
  # Provision this exact release with stage-release.sh before activation.
  revision = lib.strings.trim (builtins.readFile ./revision);
  release = "%h/.local/share/tempo/releases/${revision}";
  start = pkgs.writeShellScript "tempo-start" ''
    set -euo pipefail
    export APP_PASSWORD="$(< "$CREDENTIALS_DIRECTORY/app-password")"
    exec ${pkgs.nodejs_24}/bin/node server/index.js
  '';
in {
  systemd.user.tmpfiles.rules = [
    "d %h/.config/tempo 0700 - - -"
    "d %h/.local/share/tempo 0700 - - -"
    "d %h/.local/share/tempo/releases 0700 - - -"
    "d %h/.local/share/tempo/data 0700 - - -"
  ];

  systemd.user.services.tempo = {
    Unit = {
      Description = "Tempo personal agenda (private, single-user SQLite)";
      After = ["network.target"];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = release;
      ExecStartPre = "${pkgs.coreutils}/bin/sha256sum --check --status SHA256SUMS";
      ExecStart = "${start}";
      # Missing credentials fail closed; no optional '-' and no default password.
      LoadCredential = ["app-password:%h/.config/tempo/password"];
      Environment = [
        "NODE_ENV=production"
        "HOST=127.0.0.1"
        "PORT=3100"
        "APP_ORIGIN=https://edt.qgroget.com"
        "DATA_DIR=%h/.local/share/tempo/data"
      ];
      UMask = "0077";
      NoNewPrivileges = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      LimitCORE = 0;
      Restart = "on-failure";
      RestartSec = "10";
      TimeoutStopSec = "30";
    };
    Install.WantedBy = ["default.target"];
  };

  qgroget.services.edt = {
    subdomain = "edt";
    url = "http://127.0.0.1:3100";
    type = "private";
  };
}
