{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.jovian-nixos.nixosModules.default
  ];

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };
    "/mnt/data" = {
      device = "/dev/disk/by-label/data";
      fsType = "ext4";
      options = [
        "nofail"
        "noatime"
        "x-systemd.automount"
        "x-systemd.idle-timeout=60"
      ];
    };
  };

  environment.systemPackages = [pkgs.borgbackup];
  services.openssh.enable = true;

  hardware.enableRedistributableFirmware = true;

  nixpkgs.buildPlatform = "x86_64-linux";
  nixpkgs.hostPlatform = "aarch64-linux";
}
