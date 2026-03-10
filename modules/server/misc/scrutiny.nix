{
  config,
  lib,
  ...
}: {
  # 1. Enable the SMART daemon for Scrutiny
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
          "generic+https://webhook.site/49e976cb-a14a-4dc5-95d6-4f88052b2fa0?template=json"
          #"generic+https://n8n.qgroget.com/webhook-test/c8558b6d-c7c2-405d-bfa7-2d59836a5956"
        ];
      };
    };

    collector = {
      enable = true;
      settings.api.endpoint = "http://127.0.0.1:36468";
    };
  };

  qgroget.services.scrutiny = {
    subdomain = "scrutiny";
    type = "private";
    url = "http://127.0.0.1:36468";
  };
}
