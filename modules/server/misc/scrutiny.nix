{
  config,
  lib,
  inputs,
  ...
}: let
  # Import nixpkgs from the PR #481809 branch
  # This PR updates scrutiny with new service options and adds scrutiny-collector-zfs
  scrutinyPkgsSrc = inputs.scrutiny-nixpkgs;
in {
  # Use overlay to provide all scrutiny packages from the forked nixpkgs
  nixpkgs.overlays = [
    (final: prev: let
      scrutinyPkgs = import scrutinyPkgsSrc {
        system = prev.stdenv.hostPlatform.system;
      };
    in {
      scrutiny = scrutinyPkgs.scrutiny;
      scrutiny-collector-zfs = scrutinyPkgs.scrutiny-collector-zfs or null;
    })
  ];

  # Disable the default scrutiny module and use the one from the forked nixpkgs
  disabledModules = ["services/monitoring/scrutiny.nix"];

  imports = [
    "${scrutinyPkgsSrc}/nixos/modules/services/monitoring/scrutiny.nix"
  ];

  services.smartd = {
    enable = true;
    autodetect = true;
  };

  services.scrutiny = {
    enable = true;
    settings = {
      web.listen.port = 36468;

      notify = {
        urls = [
          "generic://n8n.qgroget.com/webhook/c8558b6d-c7c2-405d-bfa7-2d59836a5956?template=json"
        ];
      };
    };

    collector = {
      enable = true;
      settings.api.endpoint = "http://127.0.0.1:36468";
      schedule = "hourly";
    };
  };

  qgroget.services.scrutiny = {
    subdomain = "scrutiny";
    type = "private";
    url = "http://127.0.0.1:36468";
  };
}
