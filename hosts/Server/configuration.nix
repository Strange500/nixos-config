{
  inputs,
  hostname,
  lib,
  config,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../modules/server/media/jellyfin.nix
    #../../modules/system/tpm/tpm.nix
    ./disk-config.nix
  ];

  users.mutableUsers = false;

  fileSystems."/mnt/media" = {
    device = "media";
    fsType = "virtiofs";
    options = [
      "rw"
      "relatime"
      "user"
      "uid=1000"
    ];
    neededForBoot = false;
  };
  fileSystems."/mnt/appdata" = {
    device = "appdata";
    fsType = "virtiofs";
    options = [
      "ro"
      "relatime"
      "user"
    ];
    neededForBoot = false;
  };

  networking.firewall.allowedTCPPorts = [
    22
    8384 # Syncthing GUI
    22000 # Syncthing sync port
  ];

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/lib/sops".neededForBoot = true;

  environment.persistence = {
    "/persist" = {
      enable = true;
      hideMounts = true;
      directories = [
        "/var/lib/sops"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd"
        "/etc/ssh"
        "/root/.ssh"
        {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
          mode = "u=rwx,g=rx,o=";
        }
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };

  sops.secrets = {
    "syncthing/${hostname}/cert" = {
    };
    "syncthing/${hostname}/key" = {
    };
  };


  services.syncthing = {
    enable = true;

    guiAddress = "0.0.0.0:8384";
    user = "${config.qgroget.user.username}";

    cert = "${config.sops.secrets."syncthing/${hostname}/cert".path}";
    key = "${config.sops.secrets."syncthing/${hostname}/key".path}";

    settings = {
      folders = {
        "Persist" = {
          id = "r4pf2-m7vwn";
          path = "/persist";
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
        localAnnounceEnabled = false;
        globalAnnounceEnabled = true;
        relaysEnabled = true;
        urAccepted = -1;
      };
    };
  };

  # firewall
  networking.firewall = {
    enable = false;
  };

  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
