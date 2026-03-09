{...}: {
  qgroget.services.portfolio = {
    subdomain = "portfolio";
    url = "http://127.0.0.1:3001";
    type = "public";
  };

  services.portfolio = {
    enable = true;
    port = 3001;
  };
}
