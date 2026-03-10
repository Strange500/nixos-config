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
    settings.web.listen.port = 36468;

    collector = {
      enable = true;
      # 2. Hardcode the API endpoint to your custom port
      settings.api.endpoint = "http://127.0.0.1:36468";
    };
  };

  # Custom reverse proxy mapping
  qgroget.services.scrutiny = {
    subdomain = "scrutiny";
    type = "private";
    url = "http://127.0.0.1:36468";
  };
}
