{
  pkgs,
  config,
  ...
}: {
  boot.kernelParams = ["acpi_enforce_resources=lax"];

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
  users.users.${config.qgroget.user.username}.extraGroups = ["tss"];

  environment.systemPackages = with pkgs; [
    tpm2-tools
    tpm2-tss
    cryptsetup
  ];

  boot.kernelModules = ["tpm_tis" "tpm_crb"];
  boot.initrd.availableKernelModules = ["tpm_tis" "tpm_crb"];
  # `boot.initrd.systemd.enable` was removed upstream: scripted initrd is gone,
  # systemd initrd is unconditional. Defining it is a hard eval failure.
}
