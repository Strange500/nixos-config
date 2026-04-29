{
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/profiles/base.nix
    ../../modules/profiles/desktop.nix
    ./settings.nix
    ./disk-config.nix
    ../../modules/system/tpm/tpm.nix
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  boot.initrd.luks.devices = {
    cryptsystem = {
      device = lib.mkForce "/dev/nvme0n1p3";
    };
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    podman-compose
  ];

  services.upower.enable = true;

  boot.kernelParams = ["acpi_enforce_resources=lax"];
}
