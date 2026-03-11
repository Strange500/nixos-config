{
  config,
  lib,
  pkgs,
  ...
}: let
  scrutiny-fork = pkgs.scrutiny.overrideAttrs (oldAttrs: {
    src = pkgs.fetchFromGitHub {
      owner = "Starosdev";
      repo = "scrutiny";
      rev = "43ed5e8a31c81fd26a0962350cd16a5ac9b6182a";
      hash = "sha256-tK4D4QeB4K3tFjdW4ftKiWrGZ119oaUdzCvfZ4shTPw=";
    };
  });
in {
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  services.scrutiny = {
    enable = true;
    package = scrutiny-fork;
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
