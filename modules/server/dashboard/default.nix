{...}: {
  qgroget.services = {
    unraid = {
      name = "unraid";
      url = "http://192.168.0.28:80";
    };
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
