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
  };

  environment.systemPackages = with pkgs; [vim];

  services.openssh.enable = true;

  users = {
    mutableUsers = false;
    users."guest" = {
      isNormalUser = true;
      password = "guest";
      extraGroups = ["wheel"];
    };
  };

  hardware.enableRedistributableFirmware = true;

  nixpkgs.buildPlatform = "x86_64-linux";
  nixpkgs.hostPlatform = "aarch64-linux";
}
