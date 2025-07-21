{
  inputs,
  lib,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../../modules/server/media/jellyfin.nix
    #../../modules/system/tpm/tpm.nix
    ./disk-config.nix
  ];

  users.mutableUsers = false;


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
