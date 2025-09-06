{
  inputs,
  lib,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../modules/system/tpm/tpm.nix
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  # add kernel modules
  boot.kernelModules = [
    "kvm-amd"
    "vboxdrv"
    "vboxnetadp"
    "vboxnetflt"
    "vboxpci"
  ];

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = ["strange"];
  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.dragAndDrop = true;
  virtualisation.virtualbox.host.enableKvm = true;
  virtualisation.virtualbox.host.addNetworkInterface = false;

  users.mutableUsers = false;

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
  fileSystems."/var/lib/sops".neededForBoot = true;

  # # If you use NetworkManager, keep it off the AP iface:
  # networking.networkmanager.unmanaged = ["interface-name:wlp11s0"];

  # # Static IP for the AP side
  # networking.interfaces.wlp11s0.useDHCP = false;
  # networking.interfaces.wlp11s0.ipv4.addresses = [
  #   {
  #     address = "192.168.50.1";
  #     prefixLength = 24;
  #   }
  # ];

  # # hostapd: 5 GHz on channel 36 (non-DFS), FR regulatory domain
  # services.hostapd = {
  #   enable = true;
  #   radios.wlp11s0 = {
  #     band = "5g";
  #     channel = 36;
  #     countryCode = "FR";
  #     networks.wlp11s0 = {
  #       ssid = "My5GHzAP";
  #       authentication = {
  #         mode = "wpa2-sha256"; # WPA2-Personal
  #         wpaPassword = "StrongPass123";
  #       };
  #     };
  #   };
  # };

  # # DHCP/DNS for clients on wlp11s0
  # services.dnsmasq = {
  #   enable = true;
  #   settings = {
  #     interface = ["wlp11s0"];
  #     bind-interfaces = true;
  #     dhcp-range = "192.168.50.10,192.168.50.100,12h";
  #     dhcp-option = [
  #       "option:router,192.168.50.1"
  #       "option:dns-server,192.168.50.1"
  #     ];
  #   };
  # };

  # # Share internet from your uplink (replace enp3s0 with your real WAN iface)
  # networking.nat = {
  #   enable = true;
  #   externalInterface = "enp3s0";
  #   internalInterfaces = ["wlp11s0"];
  # };

  # # Allow DNS & DHCP from Wi-Fi clients
  # networking.firewall.interfaces."wlp11s0" = {
  #   allowedUDPPorts = [67 53];
  #   allowedTCPPorts = [53];
  # };

  environment.persistence = {
    "/persist" = {
      enable = true;
      hideMounts = true;
      directories = [
        "/var/lib/sops"
        "/var/lib/nixos"
        "/var/lib/bluetooth"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
        "/var/lib/systemd"
        "/etc/NetworkManager"
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
        {
          file = "/var/keys/secret_file";
          parentDirectory = {mode = "u=rwx,g=,o=";};
        }
      ];
    };
  };

  boot = {
    initrd = {
      luks.devices = {
        cryptsystem = {
          device = lib.mkForce "/dev/nvme0n1p3";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
        cryptdata = {
          device = lib.mkForce "/dev/sda1";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
      };
      systemd = {
        enable = true;
        services.rollback = {
          description = "Rollback BTRFS root subvolume to a pristine state";
          wantedBy = ["initrd.target"];
          after = ["systemd-cryptsetup@cryptsystem.service" "systemd-cryptsetup@cryptdata.service"];
          before = ["sysroot.mount"];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            # Rollback for cryptsystem
            mkdir -p /btrfs_tmp
            mount -o subvol=/ /dev/mapper/cryptsystem /btrfs_tmp
            if [[ -e /btrfs_tmp/root ]]; then
              mkdir -p /btrfs_tmp/old_roots
              timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
              mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
            fi
            delete_subvolume_recursively() {
              IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
              done
              btrfs subvolume delete "$1"
            }
            for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
              delete_subvolume_recursively "$i"
            done

            btrfs subvolume create /btrfs_tmp/root
            umount /btrfs_tmp
          '';
        };
      };
    };
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
