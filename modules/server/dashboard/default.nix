{...}: {
  qgroget.services = {
    top = {
      name = "top";
      url = "http://127.0.0.1:61208";
      type = "private";
    };
  };

  services.glances = {
    enable = true;
    port = 61208;
  };
}
