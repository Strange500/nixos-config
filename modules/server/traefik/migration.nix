{...}: let
  server = "http://192.168.0.28";
in {
  qgroget.services = {
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
