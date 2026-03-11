{
  config,
  lib,
  pkgs,
  ...
}: let
  # Import nixpkgs from the PR #481809 branch
  # This PR updates scrutiny, we'll use only scrutiny from this branch
  scrutinyPkgs =
    import (pkgs.fetchFromGitHub {
      owner = "Samasaur1";
      repo = "nixpkgs";
      rev = "3d83e50bd8f1336dfc55c627fdf52f96512ef8f6"; # branch name from the PR
      hash = "sha256-jsc6oeVz6m4vJzshA6EbjDLSHoffAC2+lOmQXTOaqxs="; # will need to be filled after first build
    }) {
      system = pkgs.system;
    };
in {
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  services.scrutiny = {
    enable = true;
    package = scrutinyPkgs.scrutiny;
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
