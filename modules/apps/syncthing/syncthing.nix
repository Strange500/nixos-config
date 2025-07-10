{
  config,
  hostname,
  ...
}: {
  sops.secrets = {
    "syncthing/${hostname}/cert" = {
    };
    "syncthing/${hostname}/key" = {
    };
  };

  services.syncthing = {
    enable = true;

    cert = "${config.sops.secrets."syncthing/${hostname}/cert".path}";
    key = "${config.sops.secrets."syncthing/${hostname}/key".path}";

    settings = {
      folders = {
        "computer" = {
          id = "rglxv-6cyvw";
          path = "${config.home.homeDirectory}";
          devices = [
            "THPSKZ7-45G7YFY-P566CM4-O5R3WMV-IVGFIXS-QPOP6VH-LIK7MGR-5G63BAY"
          ];
          ignorePerms = false;
          type = "sendreceive";
        };
      };

      devices = {
        "THPSKZ7-45G7YFY-P566CM4-O5R3WMV-IVGFIXS-QPOP6VH-LIK7MGR-5G63BAY" = {
          id = "THPSKZ7-45G7YFY-P566CM4-O5R3WMV-IVGFIXS-QPOP6VH-LIK7MGR-5G63BAY";
          name = "Server";
          addresses = ["dynamic"];
        };
      };

      options = {
        upnpEnabled = true;
        localAnnounceEnabled = true;
        globalAnnounceEnabled = true;
        relaysEnabled = true;
        urAccepted = -1;
      };
    };
  };

  home.file.".stignore".text = ''
    .*
              *.tmp
              *.log
              *~
              *.swp
              .DS_Store
              wallpaper
              nixos'';
}
