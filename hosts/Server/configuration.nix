{
  inputs,
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
    device = "media";  # Match the tag from libvirt XML
    fsType = "virtiofs";
    options = [ 
      "rw" 
      "relatime"
      "user"
    ];
  };
  fileSystems."/mnt/appdata" = {
    device = "appdata";  # Match the tag from libvirt XML
    fsType = "virtiofs";
    options = [ 
      "ro" 
      "relatime"
      "user"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

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
