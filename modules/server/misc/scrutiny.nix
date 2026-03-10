{...}: {
  services.scrutiny = {
    enable = true;
  };

  qgroget.services.scrutiny = {
    subdomain = "scrutiny";
    type = "private";
    url = "http://127.0.0.1:36468";
    settings.web.listen.port = 36468;
  };
}
