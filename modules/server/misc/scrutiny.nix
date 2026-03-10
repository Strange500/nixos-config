{...}: {
  services.scrutiny = {
    enable = true;
    settings.web.listen.port = 36468;
    collector.enable = true;
  };

  qgroget.services.scrutiny = {
    subdomain = "scrutiny";
    type = "private";
    url = "http://127.0.0.1:36468";
  };
}
