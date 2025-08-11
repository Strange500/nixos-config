{...}: let
  server = "http://192.168.0.28";
in {
  qgroget.services = {
    file = {
      name = "file";
      url = "${server}:8095";
      type = "public";
    };
    list = {
      name = "list";
      url = "${server}:5244";
      type = "private";
    };
    portfolio = {
      name = "portfolio";
      url = "${server}:3000";
      type = "public";
    };
    # syncthing = {
    #   name = "syncthing";
    #   url = "${server}:8384";
    #   type = "public";
    # };
  };
}
