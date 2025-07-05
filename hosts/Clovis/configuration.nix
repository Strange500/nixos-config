{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ./disk-config.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };


  boot.kernelParams = ["acpi_enforce_resources=lax"];

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
  users.users.strange.extraGroups = [ "tss" ];  

  boot.initrd.luks.devices = {
    cryptsystem = {
      device = lib.mkForce "/dev/nvme0n1p3";
    };
    cryptdata = {
      device = lib.mkForce "/dev/sda1";
    };
  };

  environment.systemPackages = with pkgs; [
    tpm2-tools
    tpm2-tss
    cryptsetup
  ];

  boot.kernelModules = ["tpm_tis" "tpm_crb"];
  boot.initrd.availableKernelModules = ["tpm_tis" "tpm_crb"];

  boot.initrd.systemd.enable = true;

}
