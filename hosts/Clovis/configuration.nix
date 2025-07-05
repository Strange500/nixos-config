{
  inputs,
  pkgs,
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
    useOSProber = true;
  };

  boot.kernelParams = ["acpi_enforce_resources=lax"];

  # Enable TPM support
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  # TPM-based LUKS unlocking
  boot.initrd.luks.devices = {
    cryptsystem = {
      device = "/dev/disk/by-uuid/YOUR_SYSTEM_UUID_HERE";
      crypttabExtraOpts = ["tpm2-device=auto" "tpm2-pcrs=0+2+7"];
    };
    cryptdata = {
      device = "/dev/disk/by-uuid/YOUR_DATA_UUID_HERE";
      crypttabExtraOpts = ["tpm2-device=auto" "tpm2-pcrs=0+2+7"];
    };
  };

  # Required packages
  environment.systemPackages = with pkgs; [
    tpm2-tools
    tpm2-tss
    clevis
    cryptsetup
  ];

  # Enable kernel modules for TPM
  boot.kernelModules = ["tpm_tis" "tpm_crb"];
  boot.initrd.availableKernelModules = ["tpm_tis" "tpm_crb"];

  # Use systemd in initrd for better TPM integration
  boot.initrd.systemd.enable = true;

  # Auto-enrollment service (runs after installation)
  systemd.services.tpm-luks-enroll = {
    description = "Enroll TPM keys for LUKS devices";
    wantedBy = ["multi-user.target"];
    after = ["tpm2.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "enroll-tpm-keys" ''
        # Only run if TPM keys are not already enrolled
        if ! ${pkgs.systemd}/bin/systemd-cryptenroll /dev/disk/by-uuid/YOUR_SYSTEM_UUID_HERE --tpm2-device=list | grep -q "tpm2"; then
          echo "Enrolling TPM key for system disk..."
          ${pkgs.systemd}/bin/systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 /dev/disk/by-uuid/YOUR_SYSTEM_UUID_HERE
        fi

        if ! ${pkgs.systemd}/bin/systemd-cryptenroll /dev/disk/by-uuid/YOUR_DATA_UUID_HERE --tpm2-device=list | grep -q "tpm2"; then
          echo "Enrolling TPM key for data disk..."
          ${pkgs.systemd}/bin/systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 /dev/disk/by-uuid/YOUR_DATA_UUID_HERE
        fi
      '';
    };
  };

  # Security settings
  security.polkit.enable = true;
  services.udisks2.enable = true;
}
