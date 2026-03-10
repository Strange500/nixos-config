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
          "generic+https://n8n.qgroget.com/webhook-test/c8558b6d-c7c2-405d-bfa7-2d59836a5956?@Content-Type=application/json&template=%7B%22message%22%3A%22%7B%7B.Message%7D%7D%22%7D"
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
