{
  inputs,
  lib,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    #../../modules/system/tpm/tpm.nix
    ./disk-config.nix
  ];

  users.mutableUsers = false;

 
  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
