{
  config,
  lib,
  ...
}: {
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
    };
  };

  qgroget.services.scrutiny = {
    subdomain = "scrutiny";
    type = "private";
    url = "http://127.0.0.1:36468";
  };
}
